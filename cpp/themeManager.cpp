#include <QGuiApplication>
#include <QStyleHints>
#include <QDebug>
#include <QQuickStyle>
#include <QColor>
#include <QPalette>
#include "themeManager.h"
#include "localSettings.h"

// getThemeFromSystem: (qApp->styleHints()->colorScheme() == Qt::ColorScheme::Dark)
// qputenv("QT_QUICK_CONTROLS_MATERIAL_THEME", QByteArrayLiteral("System")); // only effect once

ThemeManager::ThemeManager(QObject *parent) : QObject(parent)
{
    qDebug() << "themeManager";
#ifdef SET_DEFAULT_BY_OS
//===============================================================================
#if !defined(Q_OS_IOS) && !defined(Q_OS_MACOS) && !defined(Q_OS_ANDROID)
    if (getStyle() == "") setStyleF();
#endif
//===============================================================================
#endif
    if (getStyle() != "") QQuickStyle::setStyle(getStyle());
    connect(qApp->styleHints(), &QStyleHints::colorSchemeChanged, this, &ThemeManager::onUpdateTheme);
    qDebug() << "themeManager done";
}

QColor ThemeManager::differWindowBgColor(bool bDiffer)
{
    QPalette palette = qApp->palette();
    QColor pltWindow = palette.color(QPalette::Window);
    if (pltWindow == Qt::black) {
        pltWindow.setRgb(40, 40, 40);
    }
    if (bDiffer) {
#if defined(Q_OS_IOS) || defined(Q_OS_ANDROID) // || defined(Q_OS_MACOS)
        return isDarkTheme() ? pltWindow.lighter(150) : pltWindow.darker(150);
#else
        return isDarkTheme() ? pltWindow.lighter(122) : pltWindow.darker(122);
#endif
    }
    else {
        return pltWindow;
    }
}

QColor ThemeManager::windowBgColor()
{
#if defined(Q_OS_IOS) || defined(Q_OS_MACOS) // || defined(Q_OS_ANDROID)
    return differWindowBgColor(false);
#else
    return differWindowBgColor();
#endif
}

void ThemeManager::onUpdateTheme()
{
    emit dataChanged();
}

void ThemeManager::setStyle(const QString& strVal) {
    LocalSettings::set(APP_THEME_STYLE, strVal);
}

QString ThemeManager::getStyle()
{
    return LocalSettings::get(APP_THEME_STYLE);
}

bool ThemeManager::isStyleDefault()
{
    return getStyle() == "";
}

bool ThemeManager::isStyleM()
{
    return getStyle() == STYLE_M;
}

bool ThemeManager::isStyleU()
{
    return getStyle() == STYLE_U;
}

bool ThemeManager::isStyleF()
{
    return getStyle() == STYLE_F;
}

void ThemeManager::setStyleDefault()
{
    setStyle("");
}

void ThemeManager::setStyleM()
{
    setStyle(STYLE_M);
}

void ThemeManager::setStyleU()
{
    setStyle(STYLE_U);
}

void ThemeManager::setStyleF()
{
    setStyle(STYLE_F);
}

bool ThemeManager::isDarkTheme()
{
    bool bDark = (qApp->styleHints()->colorScheme() == Qt::ColorScheme::Dark);
    // qDebug() << "cpp: isDarkTheme = " << bDark;
    return bDark;
}

void ThemeManager::setFontSize(int iSize)
{
    LocalSettings::setInt(APP_THEME_FONT_SIZE, iSize);
}

int ThemeManager::getFontSize()
{
    return LocalSettings::getInt(APP_THEME_FONT_SIZE);
}

#if defined(Q_OS_IOS)
extern "C" void audioPlayerManager_forceLand(bool bLand);
#endif
void ThemeManager::setLand(bool bLand)
{
#if defined(Q_OS_IOS)
    audioPlayerManager_forceLand(bLand);
#endif
}
