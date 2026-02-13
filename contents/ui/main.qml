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
        id: todoModel
    }

    /* --------------------------
       PERSISTENCE
    ---------------------------*/

    function persistModel() {
        let arr = []

        for (let i = 0; i < todoModel.count; i++) {
            const item = todoModel.get(i)
            arr.push({
                text: item.text,
                done: item.done
            })
        }

        plasmoid.configuration.todos = JSON.stringify(arr)
        plasmoid.configuration.writeConfig()
    }

    function loadModel() {
    try {
        if (!item.type) item.type = "one"
        if (!item.lastCompleted) item.lastCompleted = ""


        const raw = plasmoid.configuration.todos
        if (!raw) return

        const parsed = JSON.parse(raw)
        if (!Array.isArray(parsed)) return

        const today = new Date().toISOString().slice(0, 10)

        for (let i = 0; i < parsed.length; i++) {
            let item = parsed[i]

            // Reset daily tasks if day changed
            if (item.type === "daily") {
                if (item.lastCompleted !== today) {
                    item.done = false
                }
            }

            todoModel.append(item)
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
        width: Kirigami.Units.gridUnit * 20
        height: Kirigami.Units.gridUnit * 25
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
            border.color: input.activeFocus ? "#4C8DFF" : "#444444"
        }

        color: "white"
        placeholderTextColor: "#aaaaaa"

        onAccepted: {
            console.log("ENTER HIT")

    const trimmed = text.trim()
    if (trimmed === "") return

    const selectedType =
        typeSelector.currentIndex === 1 ? "daily" : "one"

    todoModel.append({
        text: trimmed,
        done: false,
        type: selectedType,
        lastCompleted: ""
    })

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
            border.color: typeSelector.activeFocus ? "#4C8DFF" : "#444444"
        }
    }
}



            Label {
                text: "Your To Do:"
                font.bold: true
                font.pointSize: 11
                opacity: 0.85
                Layout.topMargin: 4
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                radius: 1
                color: Qt.rgba(1, 1, 1, 0.12)
                Layout.topMargin: 4
                Layout.bottomMargin: 5
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Label {
                    anchors.centerIn: parent
                    text: "No tasks yet 🎉"
                    visible: todoModel.count === 0
                    opacity: 0.5
                }

                ListView {
                    id: listView
                    anchors.fill: parent
                    model: todoModel
                    clip: true
                    spacing: 4

                    delegate: ItemDelegate {
                        width: listView.width
                        padding: 10

                        background: Rectangle {
                            radius: 10
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.14)
                            color: "transparent"
                        }

                        contentItem: RowLayout {
                            spacing: 8

                            CheckBox {
                                checked: model.done
                                onToggled: {
                                    const today = new Date().toISOString().slice(0, 10)

                                    todoModel.setProperty(index, "done", checked)

                                    if (checked && model.type === "daily") {
                                        todoModel.setProperty(index, "lastCompleted", today)
                                    }

                                    persistModel()
                                }
                            }

                            Label {
                                text: model.text
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.strikeout: model.done
                                opacity: model.done ? 0.5 : 1.0
                                verticalAlignment: Text.AlignVCenter
                            }

                            ToolButton {
                                icon.name: "edit-delete"
                                onClicked: {
                                    todoModel.remove(index)
                                    persistModel()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
