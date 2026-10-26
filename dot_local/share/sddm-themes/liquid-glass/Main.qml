import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Effects
import QtQuick.LocalStorage 2.0 as Sql

Item {
    id: root

    width: Screen.width
    height: Screen.height
    focus: isPrimaryMonitor

    // Primary monitor detection: DP-3 is 2560x1440
    property bool isPrimaryMonitor: {
        var pW = parseInt(config.PrimaryScreenWidth) || 2560;
        var pH = parseInt(config.PrimaryScreenHeight) || 1440;
        return (root.width === pW && root.height === pH) || (root.width >= 2560 && root.height >= 1440);
    }

    property bool unlocked: false
    property string currentUsername: (typeof userModel !== "undefined" && userModel.lastUser) ? userModel.lastUser : "xoviax"
    property int currentSessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property string currentSessionName: sessionBox.currentText || "Hyprland"

    property bool loginFailed: false

    function unlockScreen(initialChar) {
        if (!unlocked) {
            unlocked = true;
            syncSetUnlocked(true);
            if (isPrimaryMonitor && initialChar && initialChar.length > 0) {
                passwordInput.text = initialChar;
                passwordInput.cursorPosition = initialChar.length;
            }
            if (isPrimaryMonitor) {
                passwordInput.forceActiveFocus();
            }
        }
    }

    function lockScreen() {
        if (unlocked) {
            unlocked = false;
            syncSetUnlocked(false);
            if (isPrimaryMonitor) {
                passwordInput.text = "";
                root.forceActiveFocus();
            }
        }
    }

    function doLogin() {
        if (typeof sddm !== "undefined") {
            sddm.login(currentUsername, passwordInput.text, sessionBox.currentIndex);
        } else {
            console.log("Mock login user:", currentUsername, "session:", sessionBox.currentIndex);
        }
    }

    // Capture global keyboard input on root
    Keys.onPressed: function(event) {
        if (isPrimaryMonitor && !unlocked) {
            // Space, Enter, or Return unlocks directly
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                unlockScreen("");
                event.accepted = true;
                return;
            }
            // If user begins typing password characters, unlock and pass typed character
            if (event.text && event.text.length > 0 && event.key !== Qt.Key_Escape && event.key !== Qt.Key_Tab && event.key !== Qt.Key_Backtab) {
                unlockScreen(event.text);
                event.accepted = true;
                return;
            }
        }
    }

    function getDb() {
        return Sql.LocalStorage.openDatabaseSync("SDDM_MultiMonitor", "1.0", "SDDM Sync", 10000);
    }

    function initDb() {
        try {
            var db = getDb();
            db.transaction(function(tx) {
                tx.executeSql('CREATE TABLE IF NOT EXISTS State(key TEXT UNIQUE, value TEXT)');
            });
        } catch(e) {
            console.error("initDb error:", e);
        }
    }

    function syncSetUnlocked(val) {
        try {
            var db = getDb();
            db.transaction(function(tx) {
                tx.executeSql('INSERT OR REPLACE INTO State VALUES("unlocked", ?)', [val ? "1" : "0"]);
            });
        } catch(e) {
            console.error("syncSetUnlocked error:", e);
        }
    }

    function syncGetUnlocked() {
        try {
            var db = getDb();
            var val = "0";
            db.transaction(function(tx) {
                var res = tx.executeSql('SELECT value FROM State WHERE key = "unlocked"');
                if (res.rows.length > 0) {
                    val = res.rows.item(0).value;
                }
            });
            return val === "1";
        } catch(e) {
            return false;
        }
    }

    onIsPrimaryMonitorChanged: {
        if (isPrimaryMonitor) {
            syncSetUnlocked(false);
            root.forceActiveFocus();
        }
    }

    Component.onCompleted: {
        initDb();
        if (isPrimaryMonitor) {
            syncSetUnlocked(false);
            root.forceActiveFocus();
        }
    }

    // Polling timer to synchronize unlock state across separate QQuickViews / monitors
    Timer {
        id: syncPollTimer
        interval: 80
        repeat: true
        running: true
        onTriggered: {
            var remoteVal = syncGetUnlocked();
            if (root.unlocked !== remoteVal) {
                root.unlocked = remoteVal;
                if (root.unlocked && isPrimaryMonitor) {
                    passwordInput.forceActiveFocus();
                } else if (!root.unlocked && isPrimaryMonitor) {
                    passwordInput.text = "";
                    root.forceActiveFocus();
                }
            }
        }
    }

    // Hidden ComboBox to reliably bind to sessionModel
    ComboBox {
        id: sessionBox
        visible: false
        model: (typeof sessionModel !== "undefined") ? sessionModel : null
        textRole: "name"
        currentIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    }

    Connections {
        target: (typeof sddm !== "undefined") ? sddm : null
        function onLoginFailed() {
            if (isPrimaryMonitor) {
                loginFailed = true;
                passwordInput.selectAll();
                shakeAnimation.restart();
                resetTimer.restart();
            }
        }
        function onLoginSucceeded() {
            loginFailed = false;
        }
    }

    Timer {
        id: resetTimer
        interval: 3000
        onTriggered: loginFailed = false
    }

    // 1. Fullscreen Wallpaper (Sharp Base Layer, always visible underneath)
    Image {
        id: wallpaper
        anchors.fill: parent
        source: config.Background || "Backgrounds/current-wallpaper.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        mipmap: true
    }

    // 2. Hardware-Accelerated Frosted Blur Overlay (Visibly dissolves/unblurs when unlocked)
    MultiEffect {
        id: backgroundBlurOverlay
        anchors.fill: parent
        source: wallpaper
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        blurMultiplier: 1.8
        autoPaddingEnabled: false

        // In Step 1: Fully blurred (opacity 1.0). In Step 2: Dissolves away into crisp wallpaper (opacity 0.0)
        opacity: root.unlocked ? 0.0 : 1.0
        visible: opacity > 0.005

        Behavior on opacity {
            NumberAnimation { duration: 650; easing.type: Easing.OutCubic }
        }
    }

    // 3. Subtle Darkening Tint for Depth
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.unlocked ? 0.08 : 0.16
        Behavior on opacity { NumberAnimation { duration: 650; easing.type: Easing.OutCubic } }
    }

    // Background Click Handler (Clicking any display unlocks)
    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (!root.unlocked) {
                root.unlockScreen("");
            } else if (root.isPrimaryMonitor) {
                passwordInput.forceActiveFocus();
            }
        }
    }

    // 4. Apple-Style Header Clock & Date (Primary Monitor Only, glides up on unlock)
    Column {
        id: clockSection
        visible: root.isPrimaryMonitor
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.unlocked ? Math.max(root.height * 0.08, 40) : Math.max(root.height * 0.22, 130)
        scale: root.unlocked ? 1.0 : 1.14
        spacing: 6

        Behavior on y { NumberAnimation { duration: 550; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 550; easing.type: Easing.OutCubic } }

        Text {
            id: timeText
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: config.Font || "Inter Display, Inter, -apple-system, BlinkMacSystemFont, sans-serif"
            font.pointSize: (root.height > 0 && root.width > 0) ? Math.max(24, Math.round(Math.min(root.height * 0.08, root.width * 0.07, 76))) : 64
            font.weight: Font.DemiBold
            color: "#ffffff"
            renderType: Text.QtRendering
            style: Text.Raised
            styleColor: "#50000000"

            function updateTime() {
                text = new Date().toLocaleTimeString(Qt.locale(), config.HourFormat || "HH:mm")
            }
        }

        Text {
            id: dateText
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: config.Font || "Inter, -apple-system, BlinkMacSystemFont, sans-serif"
            font.pointSize: (root.height > 0) ? Math.max(12, Math.round(Math.min(root.height * 0.022, 18))) : 16
            font.weight: Font.Medium
            color: "#e6ffffff"
            renderType: Text.QtRendering
            style: Text.Raised
            styleColor: "#40000000"

            function updateDate() {
                text = new Date().toLocaleDateString(Qt.locale(), config.DateFormat || "dddd, MMMM d")
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                timeText.updateTime()
                dateText.updateDate()
            }
        }

        Component.onCompleted: {
            timeText.updateTime()
            dateText.updateDate()
        }
    }

    // 5. Liquid Glass Floating Login Card (Primary Monitor Only)
    Item {
        id: cardContainer
        visible: root.isPrimaryMonitor && (opacity > 0.005)
        width: Math.min(380, root.width * 0.88)
        height: 380
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(clockSection.y + clockSection.height + 40, root.height * 0.38)

        // Apple Elastic Fluid Spring Physics
        property real animY: root.unlocked ? 0 : 45
        property real animScale: root.unlocked ? 1.0 : 0.88
        property real animOpacity: root.unlocked ? 1.0 : 0.0
        property real dynamicBlur: root.unlocked ? 1.0 : 0.0
        property real dynamicMultiplier: root.unlocked ? 3.0 : 0.0

        opacity: animOpacity
        scale: animScale
        enabled: root.unlocked

        transform: [
            Translate { id: cardTranslate; x: 0; y: cardContainer.animY }
        ]

        Behavior on animY {
            NumberAnimation { duration: 560; easing.type: Easing.OutBack; easing.overshoot: 1.12 }
        }
        Behavior on animScale {
            NumberAnimation { duration: 560; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
        }
        Behavior on animOpacity {
            NumberAnimation { duration: 420; easing.type: Easing.OutQuad }
        }
        Behavior on dynamicBlur {
            NumberAnimation { duration: 550; easing.type: Easing.OutCubic }
        }
        Behavior on dynamicMultiplier {
            NumberAnimation { duration: 550; easing.type: Easing.OutCubic }
        }

        // Live backdrop sampling behind the card (samples the wallpaper)
        ShaderEffectSource {
            id: cardBackdrop
            anchors.fill: parent
            sourceItem: wallpaper
            sourceRect: Qt.rect(cardContainer.x, cardContainer.y, cardContainer.width, cardContainer.height)
            live: true
            visible: false
        }

        // Card Mask (Rounded Rect)
        Item {
            id: cardMask
            anchors.fill: parent
            visible: false
            layer.enabled: true

            Rectangle {
                anchors.fill: parent
                radius: parseInt(config.CardRadius) || 28
                color: "black"
            }
        }

        // Localized Frosted Acrylic Blur & Deep Ambient Drop Shadow
        MultiEffect {
            id: glassBlur
            anchors.fill: parent
            source: cardBackdrop
            maskEnabled: true
            maskSource: cardMask
            blurEnabled: true
            blur: cardContainer.dynamicBlur
            blurMax: 64
            blurMultiplier: cardContainer.dynamicMultiplier
            autoPaddingEnabled: false
            shadowEnabled: true
            shadowColor: "#80000000"
            shadowBlur: 0.95
            shadowVerticalOffset: 16
        }

        // Translucent Glass Surface & Specular Rim Reflection Border
        Rectangle {
            id: glassSurface
            anchors.fill: parent
            radius: parseInt(config.CardRadius) || 28
            color: "#351a243a"
            border.color: "#5cffffff"
            border.width: 1.2

            // Top specular sheen reflection gradient
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: parent.height * 0.45
                radius: parseInt(config.CardRadius) || 28
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#28ffffff" }
                    GradientStop { position: 1.0; color: "#00ffffff" }
                }
            }

            // Dynamic fluid wave sheen during transition
            Rectangle {
                anchors.fill: parent
                radius: parseInt(config.CardRadius) || 28
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#30ffffff" }
                    GradientStop { position: 0.4; color: "#10ffffff" }
                    GradientStop { position: 1.0; color: "#00ffffff" }
                }
                opacity: root.unlocked ? 0.35 : 0.0
                Behavior on opacity {
                    NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                }
            }
        }

        // Card Contents
        Column {
            anchors.centerIn: parent
            width: parent.width - 48
            spacing: 16

            // User Avatar Circle
            Rectangle {
                id: avatarCircle
                width: 84
                height: 84
                radius: 42
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#28ffffff"
                border.color: "#6effffff"
                border.width: 1.5

                Image {
                    anchors.centerIn: parent
                    width: 48
                    height: 48
                    source: "Assets/UserAvatar.svg"
                    sourceSize: Qt.size(48, 48)
                    fillMode: Image.PreserveAspectFit
                }
            }

            // User Display Name
            Text {
                id: userLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.currentUsername
                font.family: config.Font || "Inter, -apple-system, BlinkMacSystemFont, sans-serif"
                font.pointSize: 17
                font.weight: Font.DemiBold
                color: "#ffffff"
                renderType: Text.QtRendering
                style: Text.Raised
                styleColor: "#40000000"
            }

            // Password Capsule Input
            Rectangle {
                id: passwordCapsule
                width: parent.width
                height: 44
                radius: 22
                color: "#30ffffff"
                border.color: passwordInput.activeFocus ? "#ccffffff" : "#4affffff"
                border.width: passwordInput.activeFocus ? 1.5 : 1.0

                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 6
                    spacing: 8

                    Image {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        source: "Assets/Lock.svg"
                        opacity: 0.65
                        fillMode: Image.PreserveAspectFit
                    }

                    TextField {
                        id: passwordInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        font.family: config.Font || "Inter, -apple-system, BlinkMacSystemFont, sans-serif"
                        font.pointSize: 13
                        color: "#ffffff"
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        placeholderText: "Enter Password"
                        placeholderTextColor: "#85ffffff"
                        background: Item {}
                        selectByMouse: true
                        renderType: Text.QtRendering
                        onAccepted: root.doLogin()

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Escape && passwordInput.text.length === 0) {
                                root.lockScreen();
                                event.accepted = true;
                                return;
                            }
                        }
                    }

                    // Circular Submit Arrow Button
                    Rectangle {
                        id: submitBtn
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 16
                        color: passwordInput.text.length > 0 ? (submitMouse.containsMouse ? "#8fffffff" : "#66ffffff") : "#20ffffff"
                        opacity: passwordInput.text.length > 0 ? 1.0 : 0.45

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        Image {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            source: "Assets/ArrowRight.svg"
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea {
                            id: submitMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: passwordInput.text.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (passwordInput.text.length > 0) {
                                    root.doLogin()
                                }
                            }
                        }
                    }
                }
            }

            // Warning / Feedback Text
            Item {
                width: parent.width
                height: 18

                Text {
                    id: warningLabel
                    anchors.centerIn: parent
                    font.family: config.Font || "Inter, -apple-system, BlinkMacSystemFont, sans-serif"
                    font.pointSize: 11
                    font.weight: Font.Medium
                    color: root.loginFailed ? "#ff6b6b" : ((typeof keyboard !== "undefined" && keyboard.capsLock) ? "#ffd166" : "transparent")
                    text: root.loginFailed ? "Incorrect Password" : ((typeof keyboard !== "undefined" && keyboard.capsLock) ? "⇪ Caps Lock is On" : "")
                    opacity: (root.loginFailed || (typeof keyboard !== "undefined" && keyboard.capsLock)) ? 1.0 : 0.0

                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }

            // Session Selector Pill Badge
            Rectangle {
                id: sessionPill
                anchors.horizontalCenter: parent.horizontalCenter
                height: 28
                width: Math.min(sessionRow.implicitWidth + 24, parent.width - 20)
                radius: 14
                color: sessionMouse.containsMouse ? "#40ffffff" : "#22ffffff"
                border.color: "#40ffffff"
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }

                Row {
                    id: sessionRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: root.currentSessionName
                        font.family: config.Font || "Inter, -apple-system, BlinkMacSystemFont, sans-serif"
                        font.pointSize: 11
                        font.weight: Font.Medium
                        color: "#f0ffffff"
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Image {
                        width: 10
                        height: 10
                        anchors.verticalCenter: parent.verticalCenter
                        source: "Assets/ChevronDown.svg"
                        opacity: 0.75
                        fillMode: Image.PreserveAspectFit
                    }
                }

                MouseArea {
                    id: sessionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sessionPopup.open()
                }

                Popup {
                    id: sessionPopup
                    y: parent.height + 8
                    x: Math.round((parent.width - width) / 2)
                    width: 200
                    padding: 6

                    background: Rectangle {
                        radius: 14
                        color: "#eb161d2d"
                        border.color: "#4dffffff"
                        border.width: 1
                    }

                    contentItem: ListView {
                        implicitHeight: Math.min(contentHeight, 220)
                        model: (typeof sessionModel !== "undefined") ? sessionModel : 0
                        spacing: 2
                        clip: true

                        delegate: Rectangle {
                            width: parent.width
                            height: 32
                            radius: 8
                            color: itemMouse.containsMouse || index === sessionBox.currentIndex ? "#33ffffff" : "transparent"

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                text: model.name || ""
                                font.family: config.Font || "Inter, -apple-system, BlinkMacSystemFont, sans-serif"
                                font.pointSize: 11
                                font.weight: index === sessionBox.currentIndex ? Font.DemiBold : Font.Normal
                                color: "#ffffff"
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    sessionBox.currentIndex = index
                                    sessionPopup.close()
                                }
                            }
                        }
                    }
                }
            }
        }

        // Shake Animation on Failed Login
        SequentialAnimation {
            id: shakeAnimation
            NumberAnimation { target: cardTranslate; property: "x"; to: -14; duration: 40; easing.type: Easing.OutQuad }
            NumberAnimation { target: cardTranslate; property: "x"; to: 14; duration: 40; easing.type: Easing.OutQuad }
            NumberAnimation { target: cardTranslate; property: "x"; to: -10; duration: 40; easing.type: Easing.OutQuad }
            NumberAnimation { target: cardTranslate; property: "x"; to: 10; duration: 40; easing.type: Easing.OutQuad }
            NumberAnimation { target: cardTranslate; property: "x"; to: -6; duration: 40; easing.type: Easing.OutQuad }
            NumberAnimation { target: cardTranslate; property: "x"; to: 6; duration: 40; easing.type: Easing.OutQuad }
            NumberAnimation { target: cardTranslate; property: "x"; to: 0; duration: 40; easing.type: Easing.OutQuad }
        }
    }

    // 6. Apple-Style Unlock Hint (Primary Monitor Only, visible when locked)
    Rectangle {
        id: unlockHint
        visible: root.isPrimaryMonitor && (opacity > 0.005)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(root.height * 0.08, 48)
        height: 38
        width: hintRow.implicitWidth + 32
        radius: 19
        color: "#281b2438"
        border.color: "#4dffffff"
        border.width: 1

        opacity: root.unlocked ? 0.0 : 0.85

        Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutQuad } }

        Row {
            id: hintRow
            anchors.centerIn: parent
            spacing: 10

            Image {
                width: 12
                height: 12
                anchors.verticalCenter: parent.verticalCenter
                source: "Assets/ChevronDown.svg"
                rotation: 180
                opacity: 0.85
                fillMode: Image.PreserveAspectFit
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Press Space or type to unlock"
                font.family: config.Font || "Inter, -apple-system, BlinkMacSystemFont, sans-serif"
                font.pointSize: 11
                font.weight: Font.Medium
                color: "#f0ffffff"
            }
        }

        // Gentle breathing animation
        SequentialAnimation on opacity {
            running: root.isPrimaryMonitor && !root.unlocked
            loops: Animation.Infinite
            NumberAnimation { to: 0.95; duration: 1600; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.45; duration: 1600; easing.type: Easing.InOutSine }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.unlockScreen("")
        }
    }

    // 7. System Power Controls (Primary Monitor Only, visible when unlocked)
    Row {
        id: systemControls
        visible: root.isPrimaryMonitor && (opacity > 0.005)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(root.height * 0.05, 30)
        spacing: 28

        opacity: root.unlocked ? 1.0 : 0.0
        enabled: root.unlocked

        transform: [
            Translate {
                y: root.unlocked ? 0 : 25
                Behavior on y { NumberAnimation { duration: 480; easing.type: Easing.OutCubic } }
            }
        ]

        Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutQuad } }

        // Sleep
        Column {
            spacing: 6
            Rectangle {
                width: 44
                height: 44
                radius: 22
                anchors.horizontalCenter: parent.horizontalCenter
                color: sleepMouse.containsMouse ? "#48ffffff" : "#28ffffff"
                border.color: "#4affffff"
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }

                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: "Assets/Sleep.svg"
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: sleepMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof sddm !== "undefined") sddm.suspend()
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Sleep"
                font.family: config.Font || "Inter, -apple-system, BlinkMacSystemFont, sans-serif"
                font.pointSize: 10
                font.weight: Font.Medium
                color: "#d0ffffff"
            }
        }

        // Restart
        Column {
            spacing: 6
            Rectangle {
                width: 44
                height: 44
                radius: 22
                anchors.horizontalCenter: parent.horizontalCenter
                color: restartMouse.containsMouse ? "#48ffffff" : "#28ffffff"
                border.color: "#4affffff"
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }

                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: "Assets/Restart.svg"
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: restartMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof sddm !== "undefined") sddm.reboot()
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Restart"
                font.family: config.Font || "Inter, -apple-system, BlinkMacSystemFont, sans-serif"
                font.pointSize: 10
                font.weight: Font.Medium
                color: "#d0ffffff"
            }
        }

        // Shut Down
        Column {
            spacing: 6
            Rectangle {
                width: 44
                height: 44
                radius: 22
                anchors.horizontalCenter: parent.horizontalCenter
                color: powerMouse.containsMouse ? "#48ffffff" : "#28ffffff"
                border.color: "#4affffff"
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }

                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: "Assets/Power.svg"
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof sddm !== "undefined") sddm.powerOff()
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Shut Down"
                font.family: config.Font || "Inter, -apple-system, BlinkMacSystemFont, sans-serif"
                font.pointSize: 10
                font.weight: Font.Medium
                color: "#d0ffffff"
            }
        }
    }
}
