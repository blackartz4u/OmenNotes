#include "DrawingCanvas.h"

DrawingCanvas::DrawingCanvas(QQuickItem *parent) : QQuickPaintedItem(parent)
{
    // Crucial: Tell QML that this C++ item wants to receive mouse/touch events
    setAcceptedMouseButtons(Qt::AllButtons);
}

void DrawingCanvas::paint(QPainter *painter)
{
    // Turn on antialiasing so the lines are smooth, not jagged and pixelated
    painter->drawImage(0, 0, m_canvasBuffer);
}
// --- HELPER FUNCTIONS --- //

void DrawingCanvas::checkCanvasSize()
{
    QSize currentSize = boundingRect().size().toSize();
    if (m_canvasBuffer.size() != currentSize) {
        QImage newImage(currentSize, QImage::Format_ARGB32_Premultiplied);
        newImage.fill(Qt::transparent);
        QPainter p(&newImage);
        p.drawImage(0, 0, m_canvasBuffer);
        m_canvasBuffer = newImage;
    }
}

void DrawingCanvas::drawSegment(const QPointF &endPoint, qreal pressure)
{
    QPainter painter(&m_canvasBuffer);
    painter.setRenderHint(QPainter::Antialiasing);

    // Calculate line thickness based on pressure!
    // Minimum thickness is 1px. Maximum is 10px.
    qreal thickness = 1.0 + (9.0 * pressure);

    QPen pen(Qt::black, thickness, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin);
    painter.setPen(pen);

    painter.drawLine(m_lastPoint, endPoint);
    m_lastPoint = endPoint;
    update();
}

// --- INPUT EVENTS --- //

void DrawingCanvas::mousePressEvent(QMouseEvent *event)
{
    checkCanvasSize();
    m_lastPoint = event->position();
    event->accept();
}

void DrawingCanvas::mouseMoveEvent(QMouseEvent *event)
{
    // Qt 6 MAGIC: The "mouse" event knows if you are using a stylus!
    // We grab the pressure data directly from the event point.
    qreal pressure = event->points().first().pressure();

    drawSegment(event->position(), pressure);
    event->accept();
}

void DrawingCanvas::mouseReleaseEvent(QMouseEvent *event)
{
    event->accept();
}