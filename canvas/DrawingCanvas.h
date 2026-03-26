#ifndef DRAWINGCANVAS_H
#define DRAWINGCANVAS_H

#include <QQuickPaintedItem>
#include <QPainter>
#include <QImage>
#include <QMouseEvent>

class DrawingCanvas : public QQuickPaintedItem
{
    Q_OBJECT
public:
    explicit DrawingCanvas(QQuickItem *parent = nullptr);
    void paint(QPainter *painter) override;

protected:
    void mousePressEvent(QMouseEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;

private:
    void checkCanvasSize();
    void drawSegment(const QPointF &endPoint, qreal pressure);

    QImage m_canvasBuffer;
    QPointF m_lastPoint;
};

#endif // DRAWINGCANVAS_H