@CustomDialog
export struct AddContactDialog {
  controller?: CustomDialogController
  name: string = ''
  phone: string = ''
  onConfirm: (name: string, phone: string) => void = () => {
  }

  private close() {
    this.controller?.close()
  }

  build() {
    Column({ space: 12 }) {
      Text('Add Contact')
        .fontSize(20)

      TextArea({ text: this.name, placeholder: 'Name' })
        .onChange((val: string) => this.name = val)

      TextArea({ text: this.phone, placeholder: 'Phone' })
        .onChange((val: string) => this.phone = val)

      Button('Confirm')
        .onClick(() => {
          this.onConfirm(this.name.trim(), this.phone.trim())
          this.close()
        })
        .type(ButtonType.Capsule)
    }
    .backgroundColor(Color.Black)
    .padding(16)
  }
}
