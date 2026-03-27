#include "DrawingCanvas.h"

DrawingCanvas::DrawingCanvas(QQuickItem *parent) : QQuickPaintedItem(parent)
{
    setAcceptedMouseButtons(Qt::AllButtons);

    // 1. Create a massive, fixed-size canvas in memory (3:4 aspect ratio)
    m_internalSize = QSize(1536, 2048);
    m_canvasBuffer = QImage(m_internalSize, QImage::Format_ARGB32_Premultiplied);
    m_canvasBuffer.fill(Qt::transparent);
}

void DrawingCanvas::paint(QPainter *painter)
{
    // 2. Turn on smooth scaling, and stretch the 1200x1600 image to fit the current QML UI rectangle
    painter->setRenderHint(QPainter::SmoothPixmapTransform);
    painter->drawImage(boundingRect(), m_canvasBuffer);
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
    QPainter painter(&m_canvasBuffer);
    painter.setRenderHint(QPainter::Antialiasing);

    // Because our image is 1200x1600, a 1px line will look invisible.
    // We bump the base thickness up so it feels like a normal marker!
    qreal thickness = 4.0 + (5.0 * pressure);

    QPen pen(Qt::black, thickness, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin);
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
    setKeepMouseGrab(false);
    event->accept();
}