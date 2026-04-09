#ifndef EXPLORERMODEL_H
#define EXPLORERMODEL_H

#include <QSqlQueryModel>
#include <QSqlRecord>

class ExplorerModel : public QSqlQueryModel
{
    Q_OBJECT
public slots:
    void updateQuery(); // Modern replacement for refresh
public:
    // Define "Roles" so QML knows how to access the columns
    enum Roles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        IsFolderRole
    };

    explicit ExplorerModel(QObject *parent = nullptr);

    // This tells QML what "words" to use (e.g., model.name)
    QHash<int, QByteArray> roleNames() const override;
    
    // Data accessor
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

    // A function to refresh the list from the DB
    Q_INVOKABLE void refresh();
};

#endif