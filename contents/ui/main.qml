import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation


    /* --------------------------
       DATA MODEL
    ---------------------------*/
    ListModel {
        id: dailyModel
    }

    ListModel {
        id: oneTimeModel
    }

    /* --------------------------
       PERSISTENCE
    ---------------------------*/
    function persistModel() {
    let arr = []

    for (let i = 0; i < dailyModel.count; i++) {
        arr.push(dailyModel.get(i))
    }

    for (let i = 0; i < oneTimeModel.count; i++) {
        arr.push(oneTimeModel.get(i))
    }

    plasmoid.configuration.todos = JSON.stringify(arr)
    plasmoid.configuration.writeConfig()
}


    function reorderTasks() {
    let undone = []
    let done = []

    for (let i = 0; i < todoModel.count; i++) {
        const item = todoModel.get(i)

        const plainItem = {
            text: item.text,
            done: item.done,
            type: item.type,
            lastCompleted: item.lastCompleted
        }

        if (item.done) {
            done.push(plainItem)
        } else {
            undone.push(plainItem)
        }
    }

    todoModel.clear()

    for (let i = 0; i < undone.length; i++)
        todoModel.append(undone[i])

    for (let i = 0; i < done.length; i++)
        todoModel.append(done[i])
}




    function loadModel() {
    try {
       


        const raw = plasmoid.configuration.todos
        if (!raw) return

        const parsed = JSON.parse(raw)
        if (!Array.isArray(parsed)) return

        const today = new Date().toISOString().slice(0, 10)

        for (let i = 0; i < parsed.length; i++) {
            let item = parsed[i]

             if (!item.type) item.type = "one"
            if (!item.lastCompleted) item.lastCompleted = ""

            // Reset daily tasks if day changed
            if (item.type === "daily") {
                if (item.lastCompleted !== today) {
                    item.done = false
                }
            }

            if (item.type === "daily") {
            dailyModel.append(item)
        } else {
            oneTimeModel.append(item)
        }
        }

    } catch (e) {
        console.warn("Failed to load todos:", e)
    }
}


    Component.onCompleted: {
        loadModel()
    }

    /* --------------------------
       COMPACT REPRESENTATION
    ---------------------------*/

    compactRepresentation: Item {
        width: Kirigami.Units.gridUnit * 2
        height: Kirigami.Units.gridUnit * 2

        Kirigami.Icon { 
            anchors.fill: parent
            source: "view-pim-tasks"
            active: root.expanded
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }
    }

    /* --------------------------
       FULL REPRESENTATION
    ---------------------------*/

    fullRepresentation: Frame {
            id: fullRoot

    implicitWidth: Kirigami.Units.gridUnit * 60
    implicitHeight: Kirigami.Units.gridUnit * 40

    Layout.minimumWidth: implicitWidth
    Layout.minimumHeight: implicitHeight
        padding: 14

        background: Rectangle {
            radius: 14
            color: "transparent"
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            spacing: 8

            TextField {
                id: input
                placeholderText: "Add new task..."
                Layout.fillWidth: true
                Layout.preferredWidth: 3

                focus: true
                padding: 10

                background: Rectangle {
                    radius: 14
                    color: "#222222"
                    border.width: 1
                    border.color: input.activeFocus ? "#c3ff4c" : "#444444"
                }

                color: "white"
                placeholderTextColor: "#aaaaaa"

                onAccepted: {
                    console.log("ENTER HIT")

            const trimmed = text.trim()
            if (trimmed === "") return

            const selectedType =
                typeSelector.currentIndex === 1 ? "daily" : "one"

            if (selectedType === "daily") {
            dailyModel.append({
                text: trimmed,
                done: false,
                type: "daily",
                lastCompleted: ""
            })
        } else {
            oneTimeModel.append({
                text: trimmed,
                done: false,
                type: "one",
                lastCompleted: ""
            })
        }

            persistModel()
            text = ""
        }

            }

            ComboBox {
                id: typeSelector
                Layout.fillWidth: true
                Layout.preferredWidth: 1

                implicitHeight: input.implicitHeight

                model: ["One Time", "Daily"]

                contentItem: Text {
                    text: typeSelector.displayText
                    color: "white"
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    leftPadding: 10
                }

                background: Rectangle {
                    radius: 14
                    color: "#222222"
                    border.width: 1
                    border.color: typeSelector.activeFocus ? "#c3ff4c" : "#444444"
                }
            }
        }

        Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    RowLayout {
        anchors.fill: parent
        spacing: 20

        // =========================
        // DAILY (LEFT)
        // =========================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Label {
                text: "Daily"
                font.bold: true
                opacity: 0.8
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: dailyModel
                clip: true
                spacing: 4

                delegate: Item {
                    width: ListView.view.width
                    implicitHeight: row.implicitHeight + 10

                    RowLayout {
                        id: row
                        width: parent.width
                        spacing: 8

                        CheckBox {
                            checked: model.done

                            onToggled: {
                                dailyModel.setProperty(index, "done", checked)
                                persistModel()
                            }
                        }

                        Label {
                            text: model.text
                            Layout.fillWidth: true
                            font.strikeout: model.done
                            opacity: model.done ? 0.5 : 1
                        }

                       RowLayout {
    spacing: 2   // tighter gap

    ToolButton {
        icon.name: "go-up"
        enabled: index > 0

        Layout.preferredWidth: 24
        Layout.preferredHeight: 24

        icon.width: 14
        icon.height: 14

        onClicked: {
            dailyModel.move(index, index - 1, 1)
            persistModel()
        }
    }

    ToolButton {
        icon.name: "go-down"
        enabled: index < dailyModel.count - 1

        Layout.preferredWidth: 24
        Layout.preferredHeight: 24

        icon.width: 14
        icon.height: 14

        onClicked: {
            dailyModel.move(index, index + 1, 1)
            persistModel()
        }
    }

    ToolButton {
        icon.name: "edit-delete"

        Layout.preferredWidth: 24
        Layout.preferredHeight: 24

        icon.width: 14
        icon.height: 14

        onClicked: {
            dailyModel.remove(index)
            persistModel()
        }
    }
}

                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.10)
                    }
                }
            }
        }

        // Divider
        Rectangle {
            width: 1
            Layout.fillHeight: true
            color: Qt.rgba(1, 1, 1, 0.10)
        }

        // =========================
        // ONE TIME (RIGHT)
        // =========================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Label {
                text: "One Time"
                font.bold: true
                opacity: 0.8
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: oneTimeModel
                clip: true
                spacing: 4

                delegate: Item {
                    width: ListView.view.width
                    implicitHeight: row.implicitHeight + 10

                    RowLayout {
                        id: row
                        width: parent.width
                        spacing: 8

                        CheckBox {
                            checked: model.done

                            onToggled: {
                                oneTimeModel.setProperty(index, "done", checked)
                                persistModel()
                            }
                        }

                        Label {
                            text: model.text
                            Layout.fillWidth: true
                            font.strikeout: model.done
                            opacity: model.done ? 0.5 : 1
                        }

                        RowLayout {
                        spacing: 2   // tighter gap

                        ToolButton {
                            icon.name: "go-up"
                            enabled: index > 0

                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24

                            icon.width: 16
                            icon.height: 16

                            onClicked: {
                                oneTimeModel.move(index, index - 1, 1)
                                persistModel()
                            }
                        }

                        ToolButton {
                            icon.name: "go-down"
                            enabled: index < oneTimeModel.count - 1

                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24

                            icon.width: 16
                            icon.height: 16

                            onClicked: {
                                oneTimeModel.move(index, index + 1, 1)
                                persistModel()
                            }
                        }

                        ToolButton {
                            icon.name: "edit-delete"

                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24

                            icon.width: 16
                            icon.height: 16

                            onClicked: {
                                oneTimeModel.remove(index)
                                persistModel()
                            }
                        }
                    }

                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.10)
                    }
                }
            }
        }
    }
}


        }
    }
}
