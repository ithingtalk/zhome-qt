#ifndef THEMEMANAGER_H
#define THEMEMANAGER_H

#include <QQmlEngine>
#include <QStyleHints>
#include <QColor>

class ThemeManager : public QObject
{
    Q_OBJECT
    //Q_PROPERTY(QString appStyle READ getStyle WRITE setStyle)
    QML_ELEMENT

public:
    explicit ThemeManager(QObject *parent = nullptr);

public slots:
    bool isStyleDefault();
    bool isStyleM();
    bool isStyleU();
    bool isStyleF();
    void setStyleDefault();
    void setStyleM();
    void setStyleU();
    void setStyleF();
    QString getStyle();
    bool isDarkTheme();
    void setFontSize(int iSize);
    int getFontSize();
    void setLand(bool bLand);
    QColor windowBgColor();
    QColor differWindowBgColor(bool bDiffer = true);

signals:
    void dataChanged();

private:
    void setStyle(const QString& strVal);
    void onUpdateTheme();

private:
	// get/set of local storage
    const QString APP_THEME_STYLE = "APP_THEME_STYLE";
    const QString APP_THEME_FONT_SIZE = "APP_THEME_FONT_SIZE";
	
	// 1 QQuickStyle::setStyle(getStyle());
	// 2 engine.loadFromModule("Zhome", themeManagerFromCpp.getStyle());
    const QString STYLE_M = "Material";
    const QString STYLE_U = "Universal";
    const QString STYLE_F = "Fusion";

};

#endif // THEMEMANAGER_H
