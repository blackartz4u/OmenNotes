#include "DrawingCanvas.h"
#include <QCursor>
#include <QPixmap>

DrawingCanvas::DrawingCanvas(QQuickItem *parent) : QQuickPaintedItem(parent)
{
    setAcceptedMouseButtons(Qt::AllButtons);

    // 1. Create a massive, fixed-size canvas in memory (3:4 aspect ratio)
    m_internalSize = QSize(1536, 2048);
    m_canvasBuffer = QImage(m_internalSize, QImage::Format_ARGB32_Premultiplied);
    m_canvasBuffer.fill(Qt::transparent);
    m_activeStrokeBuffer = QImage(m_internalSize, QImage::Format_ARGB32_Premultiplied);
    m_activeStrokeBuffer.fill(Qt::transparent);
    // --- CUSTOM DOT CURSOR ---
    // 1. Create a tiny 8x8 pixel transparent square
    QPixmap dotCursor(4, 4);
    dotCursor.fill(Qt::transparent);

    // 2. Paint a smooth dark gray circle inside it
    QPainter cursorPainter(&dotCursor);
    cursorPainter.setRenderHint(QPainter::Antialiasing);
    cursorPainter.setBrush(QColor("#444444")); // Dark gray
    cursorPainter.setPen(Qt::NoPen);
    cursorPainter.drawEllipse(0, 0, 4, 4);
    cursorPainter.end();
    // 3. Set the "hotspot" (the exact pixel that clicks) to the center (4, 4)
    // and give it to the operating system!
    setCursor(QCursor(dotCursor, 2, 2));
    saveState();
}
void DrawingCanvas::setPenColor(const QColor &color)
{
    if (m_penColor != color) {
        m_penColor = color;
        emit penColorChanged();
    }
}

void DrawingCanvas::paint(QPainter *painter)
{
    // 2. Turn on smooth scaling, and stretch the 1200x1600 image to fit the current QML UI rectangle
    painter->setRenderHint(QPainter::SmoothPixmapTransform);
    painter->drawImage(boundingRect(), m_canvasBuffer);
    if (m_isDrawing && m_activeTool != "eraser" && m_activeTool != "stroke_eraser") {
        painter->drawImage(boundingRect(), m_activeStrokeBuffer);
    }
}

// --- THE MATH --- //

QPointF DrawingCanvas::mapToInternal(const QPointF &screenPos)
{
    // Safety check in case the UI hasn't rendered yet
    if (boundingRect().width() == 0 || boundingRect().height() == 0) return QPointF(0,0);

    // Calculate how much QML has squished or stretched our canvas
    qreal scaleX = m_internalSize.width() / boundingRect().width();
    qreal scaleY = m_internalSize.height() / boundingRect().height();

    // Multiply the mouse click by the scale to find the "true" location on the high-res image
    return QPointF(screenPos.x() * scaleX, screenPos.y() * scaleY);
}

void DrawingCanvas::drawSegment(const QPointF &endPoint, qreal pressure)
{
    // 1. CHOOSE THE LAYER: Erasers go straight to the paper, everything else floats!
    QImage *targetBuffer = (m_activeTool == "eraser" || m_activeTool == "stroke_eraser") ? &m_canvasBuffer : &m_activeStrokeBuffer;
    QPainter painter(targetBuffer);
    painter.setCompositionMode(QPainter::CompositionMode_SourceOver);
    painter.setRenderHint(QPainter::Antialiasing);
    // Start with your base color and standard pen width
    QColor drawColor = m_penColor;
    if (pressure <= 0.0) {
        pressure = 0.5;
    }
    drawColor.setAlphaF(m_brushOpacity);

    // 2. APPLY DYNAMIC SIZE:
    // We make the lightest touch 40% of whatever size you set on the slider
    qreal minWidth = qMax(4.0, m_brushSize * 0.7);
    qreal maxWidth = m_brushSize;


    // THE HIGHLIGHTER LOGIC
    if (m_activeTool == "highlighter") {
        minWidth = m_brushSize * 0.8; // Make it thick like a marker!
        maxWidth = m_brushSize * 0.8;
        // Set the Alpha (transparency) channel.
        // 0 is invisible, 255 is solid. 80 is a great highlighter sweet spot.
        drawColor.setAlpha(80);
        painter.setCompositionMode(QPainter::CompositionMode_Source);
    } else if (m_activeTool == "eraser" || m_activeTool == "stroke_eraser") {
        minWidth = m_brushSize * 1.5;
        maxWidth = m_brushSize * 1.5;
        pressure = 1.0;
        painter.setCompositionMode(QPainter::CompositionMode_Clear);
    }
    // 2. THE ANTI-CATERPILLAR MATH: Force the Pen and Highlighter to NOT stack pixels!
    if (m_activeTool != "eraser" && m_activeTool != "stroke_eraser") {
        painter.setCompositionMode(QPainter::CompositionMode_Source);
    }
    qreal dynamicWidth = minWidth + ((maxWidth - minWidth) * pressure);

    // Because our image is 1200x1600, a 1px line will look invisible.
    // We bump the base thickness up so it feels like a normal marker!
    // Pass the modified color and width into the pen
    QPen pen(drawColor);
    pen.setWidthF(dynamicWidth);
    pen.setCapStyle(Qt::RoundCap);
    pen.setJoinStyle(Qt::RoundJoin);

    painter.setPen(pen);
    painter.drawLine(m_lastPoint, endPoint);
    m_lastPoint = endPoint;
    update();
}

// --- INPUT EVENTS --- //

void DrawingCanvas::mousePressEvent(QMouseEvent *event)
{
    // 3. Translate the click before saving it!
    m_lastPoint = mapToInternal(event->position());
    m_isDrawing = true;

    // 3. Clear the floating layer for a fresh stroke!
    if (m_activeTool != "eraser" && m_activeTool != "stroke_eraser") {
        m_activeStrokeBuffer.fill(Qt::transparent);
    }
    setKeepMouseGrab(true);
    event->accept();
}

void DrawingCanvas::mouseMoveEvent(QMouseEvent *event)
{
    qreal pressure = event->points().first().pressure();

    // 4. Translate the drag coordinates!
    QPointF internalPos = mapToInternal(event->position());
    drawSegment(internalPos, pressure);
    event->accept();
}

void DrawingCanvas::mouseReleaseEvent(QMouseEvent *event)
{
    m_isDrawing = false;

    // 4. Bake the floating layer permanently onto the paper!
    if (m_activeTool != "eraser" && m_activeTool != "stroke_eraser") {
        QPainter finalPainter(&m_canvasBuffer);
        finalPainter.drawImage(0, 0, m_activeStrokeBuffer);
    }
    saveState();
    update();
    setKeepMouseGrab(false);
    event->accept();
}
void DrawingCanvas::setActiveTool(const QString &tool)
{
    if (m_activeTool != tool) {
        m_activeTool = tool;
        emit activeToolChanged();
    }
}
void DrawingCanvas::saveState() {
    // 1. If we used Undo, and then draw a NEW line, we must destroy the "Redo" future.
    while (m_undoStack.size() > m_undoIndex + 1) {
        m_undoStack.removeLast();
    }

    // 2. Take a snapshot of the current paper and add it to the stack
    m_undoStack.append(m_canvasBuffer.copy());

    // 3. Prevent RAM explosion! Limit history to 20 steps.
    if (m_undoStack.size() > 20) {
        m_undoStack.removeFirst();
    } else {
        m_undoIndex++;
    }
}

void DrawingCanvas::undo() {
    if (m_undoIndex > 0) {
        m_undoIndex--; // Go back in time
        m_canvasBuffer = m_undoStack[m_undoIndex].copy(); // Restore the snapshot
        update(); // Force the screen to redraw
    }
}

void DrawingCanvas::redo() {
    if (m_undoIndex < m_undoStack.size() - 1) {
        m_undoIndex++; // Go forward in time
        m_canvasBuffer = m_undoStack[m_undoIndex].copy(); // Restore the snapshot
        update(); // Force the screen to redraw
    }
}
void DrawingCanvas::setBrushSize(qreal size) {
    if (m_brushSize != size) {
        m_brushSize = size;
        emit brushSizeChanged();
    }
}

void DrawingCanvas::setBrushOpacity(qreal opacity) {
    if (m_brushOpacity != opacity) {
        m_brushOpacity = opacity;
        emit brushOpacityChanged();
    }
}