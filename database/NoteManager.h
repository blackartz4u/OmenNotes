#ifndef NOTEMANAGER_H
#define NOTEMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>

class NoteManager : public QObject
{
    Q_OBJECT
signals:
    void dataChanged(); // Notify the model to refresh
public:
    explicit NoteManager(QObject *parent = nullptr);
    ~NoteManager();

    // Initialize the SQLite connection and create tables
    bool initDatabase();

    // Invokable functions for your QML Sidebar
    Q_INVOKABLE void addFolder(const QString &name, int parentId = 0);

    Q_INVOKABLE void addNote(const QString &title, int folderId = 0);

    
    // For later: Loading data into your canvas
    Q_INVOKABLE QByteArray getPageData(int noteId, int pageNumber);
    Q_INVOKABLE void savePageData(int noteId, int pageNumber, const QByteArray &data);

private:
    QSqlDatabase m_db;
    bool createTables();
};

#endif // NOTEMANAGER_H