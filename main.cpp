#include <QSurfaceFormat>
#include <QGuiApplication>
#include <QQuickWindow>
#include <QQmlApplicationEngine>
#include <QWindow>
#include "canvas/DrawingCanvas.h"

// THE WINDOWS API HEADERS
#ifdef Q_OS_WIN
#include <windows.h>
#include <dwmapi.h>
#pragma comment(lib, "dwmapi.lib") // Links the Windows Blur library automatically
#endif

int main(int argc, char *argv[])
{
    // 1. Force Graphics Backend
    qputenv("QSG_RHI_BACKEND", "opengl");
    qputenv("QSG_RENDER_LOOP", "basic");
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");

    // 2. Allow Transparency at the Hardware Level
    QSurfaceFormat format;
    format.setAlphaBufferSize(8);
    QSurfaceFormat::setDefaultFormat(format);

    QGuiApplication app(argc, argv);

    qmlRegisterType<DrawingCanvas>("OmenNotes.Canvas", 1, 0, "DrawingCanvas");

    QQmlApplicationEngine engine;
    const QUrl url(u"qrc:/OmenNotes/Main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);

    engine.loadFromModule("OmenNotes", "Main");

    // --- 3. INJECT WINDOWS PREMIUM STYLING (Blur + Dark Mode + Rounded Corners) ---
#ifdef Q_OS_WIN
    if (!engine.rootObjects().isEmpty()) {
        QQuickWindow *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
        if (window) {
            window->setColor(Qt::transparent);
            HWND hwnd = reinterpret_cast<HWND>(window->winId());

            // A. Extend the Blur Frame
            MARGINS margins = {-1, -1, -1, -1};
            DwmExtendFrameIntoClientArea(hwnd, &margins);

            // B. Set Backdrop Type (3 = Acrylic)
            int backdropType = 3;
            DwmSetWindowAttribute(hwnd, 38, &backdropType, sizeof(backdropType));

            // C. Force Dark Mode (1 = On)
            int darkMode = 1;
            DwmSetWindowAttribute(hwnd, 20, &darkMode, sizeof(darkMode));

            // D. THE NEW FIX: SET ROUNDED CORNERS
            // 33 = DWMWA_WINDOW_CORNER_PREFERENCE
            // 2  = DWMWCP_ROUND (Standard Windows 11 Radius)
            int cornerPreference = 2;
            DwmSetWindowAttribute(hwnd, 33, &cornerPreference, sizeof(cornerPreference));
        }
    }
#endif

    return QGuiApplication::exec();
}