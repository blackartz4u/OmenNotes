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
    if (m_activeTool == "highlighter" && m_isDrawing) {
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
    QImage *targetBuffer = (m_activeTool == "highlighter") ? &m_activeStrokeBuffer : &m_canvasBuffer;
    QPainter painter(targetBuffer);
    painter.setCompositionMode(QPainter::CompositionMode_SourceOver);
    painter.setRenderHint(QPainter::Antialiasing);
    // Start with your base color and standard pen width
    QColor drawColor = m_penColor;
    int penWidth = 5;

    // THE HIGHLIGHTER LOGIC
    if (m_activeTool == "highlighter") {
        penWidth = 25; // Make it thick like a marker!

        // Set the Alpha (transparency) channel.
        // 0 is invisible, 255 is solid. 80 is a great highlighter sweet spot.
        drawColor.setAlpha(80);
        painter.setCompositionMode(QPainter::CompositionMode_Source);
    } else if (m_activeTool == "eraser" || m_activeTool == "stroke_eraser") {
        penWidth = 40;
        painter.setCompositionMode(QPainter::CompositionMode_Clear);
    }

    // Because our image is 1200x1600, a 1px line will look invisible.
    // We bump the base thickness up so it feels like a normal marker!
    // Pass the modified color and width into the pen
    QPen pen(drawColor);
    pen.setWidth(penWidth);
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
    if (m_activeTool == "highlighter") {
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
    if (m_activeTool == "highlighter") {
        QPainter finalPainter(&m_canvasBuffer);
        finalPainter.drawImage(0, 0, m_activeStrokeBuffer);
        update(); // Force a screen refresh
    }
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