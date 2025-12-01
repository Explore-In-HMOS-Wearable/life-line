import { contact } from '@kit.ContactsKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import relationalStore from '@ohos.data.relationalStore';
import {Contact} from '../types/Contact';

export async function addContact(context: common.UIAbilityContext, fullName: string, phoneNumber: string) {
  try {
    let contactInfo: contact.Contact = {
      name: { fullName: fullName },
      phoneNumbers: [{ phoneNumber: phoneNumber }]
    }

    contact.addContact(context, contactInfo, async (err: BusinessError, data) => {
      if (err) {
        console.error('Adding Error:', err.code);
        promptAction.showToast({
          message: 'Adding Error: ' + err.code,
          duration: 3000
        });
        return;
      }
    })
  } catch (error) {
    console.error('Unexpected error in addContact:', error);
    promptAction.showToast({
      message: 'Unexpected error occurred while adding contact',
      duration: 3000
    });
  }
}

export async function deleteContact(context: common.UIAbilityContext, key: string) {
  try {
    contact.deleteContact(context, key);
    promptAction.showToast({
      message: 'Contact deleted successfully',
      duration: 3000
    });
  } catch (error) {
    console.error('Unexpected error in deleteContact:', error);
    promptAction.showToast({
      message: 'Unexpected error occurred while deleting contact',
      duration: 3000
    });
  }
}

export async function updateContact(context: common.UIAbilityContext, id: number, fullName: string, phoneNumber: string) {
  try {
    let newContactInfo: contact.Contact = {
      name: { fullName: fullName },
      phoneNumbers: [{ phoneNumber: phoneNumber }],
      id: id
    }

    contact.updateContact(context, newContactInfo);
    let predicates = new relationalStore.RdbPredicates('contacts');
    predicates.equalTo('id', id);

    promptAction.showToast({
      message: 'Contact updated successfully',
      duration: 3000
    });
  } catch (error) {
    console.error('Unexpected error in updateContact:', error);
    promptAction.showToast({
      message: 'Unexpected error occurred while updating contact',
      duration: 3000
    });
  }
}

export async function getContacts(context: common.UIAbilityContext): Promise<Contact[]> {
  return new Promise((resolve, reject) => {
    try {
      contact.queryContacts(context, (err: BusinessError, data: contact.Contact[]) => {
        if (err) {
          console.error('Query contacts error:', err.code);
          reject(err);
          return;
        }

        if (!data || data.length === 0) {
          resolve([]);
          return;
        }

        const contactsList: Contact[] = [];

        data.forEach((contactItem) => {
          try {
            contactsList.push({
              id: contactItem.id || 0,
              key: contactItem.key || '',
              name: contactItem.name?.fullName || 'Unknown Name',
              phone: contactItem.phoneNumbers?.[0]?.phoneNumber || 'No Phone'
            });
          } catch (itemError) {
            console.warn('Skipping invalid contact item:', itemError);
          }
        });

        resolve(contactsList);

      })
    } catch (error) {
      console.error('Unexpected error in getContacts:', error);
      promptAction.showToast({
        message: 'Error: ' + (error as BusinessError).code,
        duration: 3000
      });
      reject(error);
    }
  })
}