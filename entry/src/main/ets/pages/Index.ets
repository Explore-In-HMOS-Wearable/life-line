import contact from '@ohos.contact';
import call from '@ohos.telephony.call';
import common from '@ohos.app.ability.common';
import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@ohos.base';
import PermissionsUtil from '../utils/PermissionsUtil';
import { getContacts } from '../utils/ContactUtils';
import { AddContactDialog } from './ContactDialog';

import {
  LengthMetrics,
  LengthUnit,
  ArcButtonOptions,
  ArcButtonStatus,
  ArcButtonStyleMode,
  ArcButtonPosition,
  display
} from '@kit.ArkUI';

@Entry
@Component
struct Index {
  @State heartRate: number = 0;
  status: Resource = $r('app.string.status_no');
  @State emergencyContact: string = '';
  @State contactNumber: string = '';
  // Heart rate thresholds
  private readonly LOW_THRESHOLD: number = 40;
  private readonly HIGH_THRESHOLD: number = 140;
  private readonly ABNORMAL_DURATION: number = 10000; // 10 seconds
  private abnormalStartTime: number = 0;
  private isMonitoring: boolean = false;
  private sensorId: number = -1;
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  @State selectedContact: string = 'No contact selected';
  scroller: Scroller = new Scroller()
  screenW: number = 360;
  screenH: number = 360;
  dialogController: CustomDialogController | null = null
  topOptions: ArcButtonOptions = new ArcButtonOptions({});

  aboutToAppear(): void {
    try {
      const d = display.getDefaultDisplaySync();
      this.screenW = d.width;
      this.screenH = d.height;
    } catch (e) {
      console.warn('display.getDefaultDisplaySync failed, using defaults.');
    }

    this.topOptions = new ArcButtonOptions({
      label: 'Add',
      status: ArcButtonStatus.NORMAL,
      position: ArcButtonPosition.TOP_EDGE,
      styleMode: ArcButtonStyleMode.EMPHASIZED_LIGHT,
      fontSize: new LengthMetrics(15, LengthUnit.FP),
      shadowEnabled: true,
      onClick: () => {
        this.dialogController?.open()
      }
    })

    this.dialogController = new CustomDialogController({
      builder: AddContactDialog({
        onConfirm: (name: string, phone: string): void => this.addContact(name, phone)
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      customStyle: true,
      width: this.screenW,
      height: this.screenH,
      cornerRadius: 0,
      backgroundColor: Color.Transparent
    });
  }

  build() {
    Scroll() {
      Column() {
        // Header Section
        Column() {
          Text($r('app.string.heart_rate_monitor'))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.heart_rate_font'))
            .margin({ bottom: 10 })

          Text($r('app.string.emergency_alert_system'))
            .fontSize(14)
            .fontColor($r('app.color.general_font_color_3'))
            .margin({ bottom: 30 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        // Heart Rate Display Section
        Column() {
          Text($r('app.string.current_heart_rate'))
            .fontSize(16)
            .fontColor($r('app.color.general_font_color'))
            .margin({ bottom: 5 })

          Text( $r('app.string.heart_rate', this.heartRate ) )
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getHeartRateColor())
            .margin({ bottom: 10 })

          Text( this.status )
            .fontSize(14)
            .fontColor('#666666')
            .margin({ bottom: 20 })
        }
        .width('100%')
        .padding(20)
        .backgroundColor($r('app.color.bg_color_3'))
        .borderRadius(16)
        .alignItems(HorizontalAlign.Center)
        .margin({ bottom: 20 })

        // Emergency Contact Section
        Column() {
          Text($r('app.string.emergency_contact'))
            .fontSize(16)
            .fontColor($r('app.color.emergency_alert_system_font'))
            .fontWeight(FontWeight.Bolder)
            .margin({ bottom: 15 })

          Row() {
            Text($r('app.string.em_name'))
              .fontSize(14)
              .fontColor($r('app.color.general_font_color_3'))
              .width('30%')
            Text(this.emergencyContact || $r('app.string.not_set'))
              .fontSize(14)
              .fontColor($r('app.color.general_font_color'))
              .width('70%')
          }
          .width('100%')
          .margin({ bottom: 10 })

          Row() {
            Text($r('app.string.phone'))
              .fontSize(14)
              .fontColor($r('app.color.general_font_color_3'))
              .width('30%')
            Text(this.selectedContact || $r('app.string.not_set'))
              .fontSize(14)
              .fontColor($r('app.color.general_font_color'))
              .width('70%')
          }
          .width('100%')
          .margin({ bottom: 15 })
        }
        .width('100%')
        .padding(15)
        .backgroundColor($r('app.color.bg_color_2'))
        .borderRadius(12)
        .margin({ bottom: 20 })

        // Control Buttons Section
        Column() {
          Button($r('app.string.start_monitoring'))
            .onClick(() => {
              this.startHeartRateMonitoring();
            })
            .width('100%')
            .height(40)
            .backgroundColor($r('app.color.bg_color'))
            .fontColor($r('app.color.general_font_color_2'))
            .margin({ bottom: 10 })

          Button($r('app.string.stop_monitoring'))
            .onClick(() => {
              this.stopHeartRateMonitoring();
            })
            .width('100%')
            .height(40)
            .backgroundColor($r('app.color.status_bg_1'))
            .fontColor($r('app.color.general_font_color_2'))
            .margin({ bottom: 10 })

          Button($r('app.string.set_emergency_contact'))
            .onClick(() => {
              this.dialogController?.open()
            })
            .width('100%')
            .height(40)
            .backgroundColor($r('app.color.status_bg_2'))
            .fontColor($r('app.color.general_font_color_2'))
            .margin({ bottom: 10 })

          Button($r('app.string.test_emergency_call'))
            .onClick(() => {
              this.triggerEmergencyCall();
            })
            .width('100%')
            .height(40)
            .backgroundColor($r('app.color.status_bg_3'))
            .fontColor($r('app.color.general_font_color_2'))
            .margin({ bottom: 10 })
        }
        .width('100%')

        // Information Section
        Column() {
          Text($r('app.string.safety_information'))
            .fontSize(16)
            .fontWeight(FontWeight.Bolder)
            .fontColor($r('app.color.emergency_alert_system_font'))
            .margin({ bottom: 10 })

          Text($r('app.string.desc_1'))
            .fontSize(12)
            .fontColor($r('app.color.emergency_alert_system_font'))
            .margin({ bottom: 5 })

          Text($r('app.string.desc_2'))
            .fontSize(12)
            .fontColor($r('app.color.emergency_alert_system_font'))
            .margin({ bottom: 5 })

          Text($r('app.string.desc_3'))
            .fontSize(12)
            .fontColor($r('app.color.emergency_alert_system_font'))
            .margin({ bottom: 5 })
        }
        .width('100%')
        .padding(15)
        .backgroundColor($r('app.color.bg_color_4'))
        .borderRadius(12)
        .margin({ top: 20 })

        Blank()
          .height(40)
      }
      .width('100%')
      .padding(20)
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.On)
    .scrollBarColor(String($r('app.color.bg_color')))
    .scrollBarWidth(4)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.start_window_background'))
    .onDisAppear(() => {
      this.stopHeartRateMonitoring();
    })
  }

  private addContact(name: string, phone: string) {
    this.contactNumber= phone
    this.emergencyContact = name
    this.selectedContact = phone
  }
  // Start heart rate monitoring
  startHeartRateMonitoring() {
    const INTERVAL = 2000;
    PermissionsUtil.requestPermissions([
      'ohos.permission.READ_HEALTH_DATA'], this.context)
    sensor.getSensorList((error: BusinessError, data: Array<sensor.Sensor>) => {
      if (error) {
        console.error('getSensorList failed');
      } else {
        console.info('getSensorList success');
        for (let i = 0; i < data.length; i++) {
          console.info(JSON.stringify(data[i]));
        }
      }
    })
    try {
      sensor.on(sensor.SensorId.HEART_RATE, (data: sensor.HeartRateResponse) => {
        this.heartRate = data.heartRate

        this.checkHeartRateAbnormalities()
      }, { interval: INTERVAL });

    } catch (error) {
      let e: BusinessError = error as BusinessError;
      console.error(`Failed to invoke on. Code: ${e.code}, message: ${e.message}`);
    }
  }

  // Stop heart rate monitoring
  stopHeartRateMonitoring() {
    if (this.sensorId !== -1) {
      sensor.off(this.sensorId);
      this.sensorId = -1;
    }
    this.isMonitoring = false;
    this.status =  $r('app.string.monitoring_stopped');
    console.info('Heart rate monitoring stopped');
  }

  // Check for abnormal heart rate patterns
  checkHeartRateAbnormalities() {
    if (this.heartRate < this.LOW_THRESHOLD || this.heartRate > this.HIGH_THRESHOLD) {
      if (this.abnormalStartTime === 0) {
        // First detection of abnormality
        this.abnormalStartTime = Date.now();
        this.status =  $r('app.string.abnormal_status' )
        console.warn(`Abnormal heart rate detected: ${this.heartRate} BPM`);
      } else {
        // Check if abnormality has persisted for the defined duration
        const currentTime = Date.now();
        if (currentTime - this.abnormalStartTime >= this.ABNORMAL_DURATION) {
          this.triggerEmergencyCall();
          this.abnormalStartTime = 0; // Reset after triggering
        }
      }
    } else {
      // Heart rate is normal, reset the timer
      this.abnormalStartTime = 0;
      this.status = $r('app.string.normal_status')
    }
  }

  // Trigger emergency call
  async triggerEmergencyCall() {
    if (!this.contactNumber) {
      this.status = $r('app.string.status_emergency_call' );
      console.error('No emergency contact number available');
      return;
    }

    this.status =  $r('app.string.status_emergency_call_started' );
    console.info(`Initiating emergency call to: ${this.contactNumber}`);

    try {
      await call.makeCall(this.contactNumber);
      this.status = $r('app.string.status_emergency_call_started' );

    } catch (error) {
      console.error('Failed to make emergency call:', error);
      this.status = $r('app.string.status_emergency_call_started' );
    }
  }

  // Set emergency contact from contacts
  async setEmergencyContact() {
    let contacts = await  contact.selectContacts();
    try {
      this.pickEmergencyContact();

    } catch (error) {
      console.error('Failed to set emergency contact:', error);
      this.status = $r('app.string.status_emergency_call_failed' );
    }
  }

  // Simplified contact picking for wearable
  async pickEmergencyContact() {
    PermissionsUtil.requestPermissions([
      'ohos.permission.READ_CONTACTS'], this.context)
  }

  // Save emergency contact to persistent storage
  async saveEmergencyContact() {
    // You can use Preferences or other storage mechanisms here
    // This is a simplified implementation
    console.info(`Saving emergency contact: ${this.emergencyContact}, ${this.contactNumber}`);
  }

  // Get heart rate color based on value
  getHeartRateColor(): ResourceColor {
    if (this.heartRate === 0) {return '#666666';}
    if (this.heartRate < this.LOW_THRESHOLD || this.heartRate > this.HIGH_THRESHOLD) {return '#FF3B30';}
    return '#34C759';
  }
  // Show contact selection dialog
  showContactSelection(contacts: Array<contact.Contact>) {
    // Create a custom dialog or use system picker if available
    if (contacts.length > 0) {
      // For demo, select first contact
      const selected = contacts[0];
      this.selectedContact = `${selected.name}`;
    }
  }

  // Adapted contact selection function to update the @State variable
  async pickContact() {
    PermissionsUtil.requestPermissions([
      'ohos.permission.READ_CONTACTS'], this.context)

    let contacts = await getContacts(this.context)

    contact.selectContacts({
      isMultiSelect:false
    }, (err: BusinessError, data) => {
      if (err) {
        console.error(`Failed to select Contacts. Code: ${err.code}, message: ${err.message}`);
        return;
      }
      console.info(`Succeeded in selecting Contacts. data->${JSON.stringify(data)}`);
      this.showContactSelection(data)
    });
  }
}