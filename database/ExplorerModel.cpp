#include "ExplorerModel.h"

ExplorerModel::ExplorerModel(QObject *parent) : QSqlQueryModel(parent) {
    refresh();
}

void ExplorerModel::refresh() {
    // This query gets both Folders and Notes in one list
    // We add a fake column 'is_folder' (1 for folders, 0 for notes)
    setQuery("SELECT id, name, 1 as is_folder FROM Folders "
             "UNION ALL "
             "SELECT id, title as name, 0 as is_folder FROM Notes "
             "ORDER BY is_folder DESC, name ASC");
}

QVariant ExplorerModel::data(const QModelIndex &index, int role) const {
    if (role < Qt::UserRole) return QSqlQueryModel::data(index, role);

    // Map roles to column indexes
    int columnIdx = 0;
    if (role == IdRole) columnIdx = 0;
    else if (role == NameRole) columnIdx = 1;
    else if (role == IsFolderRole) columnIdx = 2;

    return QSqlQueryModel::data(this->index(index.row(), columnIdx), Qt::DisplayRole);
}

QHash<int, QByteArray> ExplorerModel::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[NameRole] = "name";
    roles[IsFolderRole] = "isFolder";
    return roles;
}
void ExplorerModel::updateQuery() {
    // Re-run the same query. Qt handles the "refresh" signals internally.
    setQuery("SELECT id, name, 1 as is_folder FROM Folders "
             "UNION ALL "
             "SELECT id, title as name, 0 as is_folder FROM Notes "
             "ORDER BY is_folder DESC, name ASC");
}