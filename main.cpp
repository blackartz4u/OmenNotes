#include <QSurfaceFormat>
#include <QGuiApplication>
#include <QQuickWindow>
#include <QQmlApplicationEngine>
#include <QWindow> // 1. Added so we can manipulate the QML Window!
#include "canvas/DrawingCanvas.h"

// 2. THE WINDOWS API HEADERS
#ifdef Q_OS_WIN
#include <windows.h>
#include <dwmapi.h>
#endif

int main(int argc, char *argv[])
{
    // 1. Force Qt to use OpenGL instead of Direct3D 11
    qputenv("QSG_RHI_BACKEND", "opengl");

    // (Optional: If OpenGL fails, you can try "vulkan" or "d3d12" instead)

    qputenv("QSG_RENDER_LOOP", "basic");
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");
    // 2. FORCE THE GRAPHICS CARD TO ALLOW TRANSPARENCY!
    // This MUST happen before QGuiApplication is created.
    QSurfaceFormat format;
    format.setAlphaBufferSize(8);
    QSurfaceFormat::setDefaultFormat(format);

    QGuiApplication app(argc, argv);

    qmlRegisterType<DrawingCanvas>("OmenNotes.Canvas", 1, 0, "DrawingCanvas");

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("OmenNotes", "Main");

    // --- 3. INJECT THE WINDOWS BLUR ---
#ifdef Q_OS_WIN
    if (!engine.rootObjects().isEmpty()) {
        QQuickWindow *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
        if (window) {

            // FIX 1: Force the C++ hardware window to actually drop its background
            // THE FIX: Force Qt to sync the graphics buffer with Windows 11 DWM

            window->setColor(Qt::transparent);


            HWND hwnd = reinterpret_cast<HWND>(window->winId());

            // FIX 2: Extend the Windows frame to cover the entire center of the app
            // A margin of -1 tells Windows to stretch the blur infinitely inward
            MARGINS margins = {-1, -1, -1, -1};
            DwmExtendFrameIntoClientArea(hwnd, &margins);

            // FIX 3: Use the correct Microsoft Magic Numbers!
            // 2 = Mica (Subtle tinting based on your wallpaper)
            // 3 = Acrylic (Heavy, classic frosted glass blur)
            // 4 = Mica Alt (Tinting with slight blur)
            int backdropType = 3;
            DwmSetWindowAttribute(hwnd, 38, &backdropType, sizeof(backdropType));

            // Force the Windows Title Bar into Dark Mode
            int darkMode = 0;
            DwmSetWindowAttribute(hwnd, 20, &darkMode, sizeof(darkMode));
        }
    }
#endif
    return QCoreApplication::exec();
}