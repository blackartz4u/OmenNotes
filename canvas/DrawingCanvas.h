#ifndef DRAWINGCANVAS_H
#define DRAWINGCANVAS_H

#include <QQuickPaintedItem>
#include <QPainter>
#include <QImage>
#include <QMouseEvent>

class DrawingCanvas : public QQuickPaintedItem
{
    Q_OBJECT
    // 1. THE DOOR: This lets QML directly bind to your C++ color!
    Q_PROPERTY(QColor penColor READ penColor WRITE setPenColor NOTIFY penColorChanged)
    Q_PROPERTY(QString activeTool READ activeTool WRITE setActiveTool NOTIFY activeToolChanged)
public:
    explicit DrawingCanvas(QQuickItem *parent = nullptr);
    void paint(QPainter *painter) override;
    // 2. The Getter and Setter
    QColor penColor() const { return m_penColor; }
    void setPenColor(const QColor &color);
    QString activeTool() const { return m_activeTool; }
    void setActiveTool(const QString &tool);
signals:
    // 3. The Signal that tells QML it worked
    void penColorChanged();
    void activeToolChanged();
protected:
    void mousePressEvent(QMouseEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;

private:
    // 1. New helper function to translate screen clicks to image coordinates
    QPointF mapToInternal(const QPointF &screenPos);
    void drawSegment(const QPointF &endPoint, qreal pressure);

    QImage m_canvasBuffer;
    QImage m_activeStrokeBuffer;
    bool m_isDrawing = false;
    QPointF m_lastPoint;
    QSize m_internalSize; // 2. Our fixed high-res memory size
    // 4. The actual variable holding the current color (defaults to black)
    QColor m_penColor = QColor("#1c1c1e");
    QString m_activeTool = "pen";
};

#endif // DRAWINGCANVAS_H