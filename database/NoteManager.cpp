#include "NoteManager.h"

NoteManager::NoteManager(QObject *parent) : QObject(parent) {
    if (!initDatabase()) {
        qCritical() << "Failed to initialize the Omen database!";
    }
}

NoteManager::~NoteManager() {
    if (m_db.isOpen()) m_db.close();
}

bool NoteManager::initDatabase() {
    // 1. Setup the storage path (StandardPaths handles Windows/macOS/Linux locations)
    QString path = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir dir(path);
    if (!dir.exists()) dir.mkpath(".");

    QString dbPath = dir.filePath("omen_notes.db");
    qDebug() << "Database Path:" << dbPath;

    // 2. Initialize SQLite Driver
    m_db = QSqlDatabase::addDatabase("QSQLITE");
    m_db.setDatabaseName(dbPath);

    if (!m_db.open()) {
        qCritical() << "Error: connection with database failed";
        return false;
    }

    return createTables();
}

bool NoteManager::createTables() {
    QSqlQuery query;

    // Table 1: Folders
    query.exec("CREATE TABLE IF NOT EXISTS Folders ("
               "id INTEGER PRIMARY KEY AUTOINCREMENT, "
               "parent_id INTEGER, "
               "name TEXT)");

    // Table 2: Notes (The "Files")
    query.exec("CREATE TABLE IF NOT EXISTS Notes ("
               "id INTEGER PRIMARY KEY AUTOINCREMENT, "
               "folder_id INTEGER, "
               "title TEXT, "
               "FOREIGN KEY(folder_id) REFERENCES Folders(id))");

    // Table 3: Pages (The Drawing Data)
    return query.exec("CREATE TABLE IF NOT EXISTS Pages ("
                      "id INTEGER PRIMARY KEY AUTOINCREMENT, "
                      "note_id INTEGER, "
                      "page_num INTEGER, "
                      "ink_data BLOB, "
                      "FOREIGN KEY(note_id) REFERENCES Notes(id))");
}

void NoteManager::addFolder(const QString &name, int parentId) {
    QSqlQuery query;
    query.prepare("INSERT INTO Folders (name, parent_id) VALUES (:name, :pid)");
    query.bindValue(":name", name);
    query.bindValue(":pid", parentId);
    if (query.exec()) {
        emit dataChanged(); // <--- Important: This triggers the UI refresh
    } else {
        qDebug() << "SQL Error (Add Folder):" << query.lastError().text();
    }
}

void NoteManager::addNote(const QString &title, int folderId) {
    QSqlQuery query;
    query.prepare("INSERT INTO Notes (title, folder_id) VALUES (:title, :fid)");
    query.bindValue(":title", title);
    query.bindValue(":fid", folderId);
    if (query.exec()) {
        emit dataChanged(); // <--- Important: This triggers the UI refresh
    } else {
        qDebug() << "SQL Error (Add Note):" << query.lastError().text();
    }

}

void NoteManager::savePageData(int noteId, int pageNumber, const QByteArray &data) {
    QSqlQuery query;
    // UPSERT logic: Update if exists, otherwise insert
    query.prepare("INSERT OR REPLACE INTO Pages (note_id, page_num, ink_data) "
                  "VALUES (:nid, :pnum, :data)");
    query.bindValue(":nid", noteId);
    query.bindValue(":pnum", pageNumber);
    query.bindValue(":data", data);
    query.exec();
}

QByteArray NoteManager::getPageData(int noteId, int pageNumber) {
    QSqlQuery query;
    query.prepare("SELECT ink_data FROM Pages WHERE note_id = :nid AND page_num = :pnum");
    query.bindValue(":nid", noteId);
    query.bindValue(":pnum", pageNumber);

    if (query.exec() && query.next()) {
        return query.value(0).toByteArray();
    }
    return QByteArray();
}