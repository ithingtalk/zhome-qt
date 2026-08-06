#ifndef _HIAIRMEMO_H
#define _HIAIRMEMO_H

#include <sys/types.h>

// localcmd
#define P2P_CMD_TAG_BROADCAST_SEARCH_TNAS     "T-NAS?"
#define P2P_CMD_TAG_BROADCAST_FIND_TNAS       "FIND_TNAS"
#define HI_LOCALCMD_PORT                      "12345"

// ======== Sync with Phone APP ========================
//config device key
#define CMD_KEY_CONFIG_DEVICE		"config_device"
//check admin login
#define CMD_KEY_ADMIN_LOGIN       	"check_admin_login"
#define CMD_KEY_USER_ID         	"user_id"
#define CMD_KEY_USER_DIR         	"phone_id"
#define CMD_KEY_GET_STATUS          "idevice_key_get_status"
#define CMD_VAL_GET_STATUS          "now"
#define CMD_KEY_DATE                "date"
#define CMD_KEY_UPTIME              "uptime"
#define CMD_KEY_VERSION             "fw_version"
#define CMD_KEY_TIME_STAMP          "time_stamp"
#define CMD_KEY_USER_AUTHORITY      "user_authority"
#define CMD_KEY_USER_ROLE           "role"
#define CMD_KEY_ADMIN_USER			"admin"
#define CMD_KEY_ADMIN_PWD           "admin_pwd"
#define CMD_KEY_CHANGE_ADMIN_PWD	"change_admin_pwd"
#define CMD_KEY_DEVICE_NAME         "device_name"
#define CMD_KEY_GET_USER_LIST		"get_user_list"
#define CMD_KEY_GET_USER_DB_DIR		"get_user_db_dir"
#define CMD_KEY_RET_USER_DB_DIR     "user_db_dir"
#define CMD_KEY_USER_LOGIN			"check_user_login"
#define CMD_KEY_USER_EMAIL			"email_account"
#define CMD_KEY_USER_PASSWD       	"user_passwd"
#define CMD_KEY_LOGIN_FORGET_PWD    "local_forget_pwd"
#define CMD_KEY_RANDOM_CODE			"random_code"
#define CMD_KEY_NEW_PWD				"new_passwd"
#define CMD_KEY_LOGIN_RESET_PWD     "local_reset_pwd"
#define CMD_KEY_SET_USER_NICKNAME   "set_user_nickname"
// ota
#define CMD_KEY_OTA_URL             "ota_url"
#define CMD_KEY_OTA_ENABLED         "ota_enabled"
#define CMD_KEY_OTA_STARTED         "ota_started"
#define CMD_KEY_OTA_STATUS          "ota_status"
#define CMD_VAL_ENABLED             "1"
#define CMD_VAL_DISABLED            "0"
//OTA info
#define OTA_SERVER_URL            "hk.hopeiot.net"
#define OTA_SERVER_PORT          "80"
#define CMD_KEY_CHECK_RFW                "check_new_rfw"
#define CMD_KEY_REMOTE_UPGRADE          "remote_upgrade"
#define CMD_REMOTE_FWINFO                   "rfw_info"
#define CMD_KEY_GET_RFWPROGRESS         "get_rfw_progress"
#define CMD_RFWPROGRESS                "rfw_progress_info"

// status
#define CMD_KEY_IPADDR              "ip_addr"
#define CMD_KEY_MACADDR             "mac_addr"
#define CMD_KEY_MEMINFO             "mem_info"
#define CMD_KEY_LOADAVG             "loadavg"
#define CMD_KEY_NUM_NEW_USER		"num_new_user"
//cfg parameters.
#define CMD_KEY_WAN_TYPE            "wan_type"
#define CMD_VAL_WAN_TYPE_DHCP       "wan_type_dhcp"
#define CMD_VAL_WAN_TYPE_STATICIP   "wan_type_staticip"
#define CMD_KEY_STATIC_IP           "static_ip"
#define CMD_KEY_GATEWAY             "gateway"
#define CMD_KEY_DNS1                "dns1"
#define CMD_KEY_DNS2                "dns2"
#define CMD_KEY_SAMBA_ENABLED       "samba_enabled"
#define CMD_KEY_SAMBA_PASSWD        "samba_passwd"
#define CMD_KEY_FTP_ENABLED         "ftp_enabled"
#define CMD_KEY_FTP_PASSWD          "ftp_passwd"
#define CMD_KEY_TELNET_ENABLED      "telnet_enabled"
#define CMD_KEY_TELNET_PASSWD       "telnet_passwd"
#define CMD_KEY_CPU_TEMP            "cpu_temp"
#define CMD_KEY_HDD_TEMP            "hdd_temp"
#define CMD_KEY_FAN_STATUS          "fan_status"
#define CMD_KEY_GET_HDD_STATUS      "get_hdd_status"
#define CMD_KEY_COPY_HARD_DISK_CONTENT "copy_hard_disk_content"
#define CMD_KEY_REPLACE_HARD_DISK   "replace_hard_disk"
#define CMD_KEY_STEP                "step"
#define CMD_VAL_STEP_PREPARE        "prepare"
#define CMD_VAL_STEP_START          "start"
#define CMD_VAL_STEP_STATUS         "status"
#define CMD_KEY_STATUS              "status"
#define CMD_VAL_STATUS_INIT         "init"
#define CMD_VAL_STATUS_COPY         "copy"
#define CMD_VAL_STATUS_FINISH       "finish"
#define CMD_VAL_STATUS_ERROR        "error"
#define CMD_VAL_STATUS_IDLE         "idle"
#define CMD_KEY_PROGRESS            "progress"
#define CMD_KEY_ERROR_CODE          "error_code"
#define CMD_VAL_ERR_NO_USB          "no_usb"
#define CMD_VAL_ERR_DISK_TOO_SMALL  "disk_too_small"
#define CMD_VAL_ERR_FORMAT_FAILED   "format_failed"
#define CMD_VAL_ERR_COPY_FAILED     "copy_failed"
#define CMD_KEY_ERR_MESSAGE         "error_message"
#define CMD_KEY_USB_SIZE            "usb_size"
#define CMD_KEY_HDD_USED_SIZE       "hdd_used_size"
 #define CMD_KEY_NEW_DISK_STATE			"new_disk_state"
#define CMD_KEY_GET_NEW_DISK_STATE  "get_new_disk_state" //for HDD backup.
 #define CMD_KEY_COPY_PERCENTAGE		"copy_percentage"
 #define CMD_KEY_COPY_RATE				"copy_rate"
#define CMD_KEY_DB_FILE_TIME		"user_db_file_time"

#define CMD_KEY_GET_ADMIN_DEVICE_STATUS "CMD_KEY_GET_ADMIN_DEVICE_STATUS"
#define CMD_KEY_ERROR_MESSAGE "CMD_KEY_ERROR_MESSAGE"
#define CMD_KEY_GET_HDD_FORMAT_PROGRESS "CMD_KEY_GET_HDD_FORMAT_PROGRESS"

#define CMD_PAR_USER_NUMBER			"user_total"
#define CMD_PAR_ADMIN_USER          "admin_user"
#define CMD_PAR_USER_LIST			"user_list"
#define CMD_PARA_SHARED_NUMBER		"num_shared_file"

// storage
#define CMD_KEY_HOTPLUG_USB         "hotplug_usb"
#define CMD_KEY_USB_DISK_LIST		"usb_disk_list"
#define CMD_VAL_HOTPLUG_USB_INSERT  "insert_usb"
#define CMD_VAL_HOTPLUG_USB_REMOVE  "remove_usb"
#define CMD_KEY_HDD_STATUS          "hdd_status"
#define CMD_VAL_HDD_STATUS_NONE     "hdd_none"
#define CMD_VAL_HDD_STATUS_UNINIT   "hdd_uninit"
#define CMD_VAL_HDD_STATUS_READY    "hdd_ready"
#define CMD_VAL_HDD_STATUS_INITING  "hdd_initing"
// usb disk
#define CMD_KEY_USB_STATUS    			"usb_status"
#define CMD_KEY_USB_CREATE_DIRECTORY	"usb_create_directory"
#define CMD_KEY_GET_USB_STATUS      	"get_usb_disk_status"
#define CMD_KEY_GET_USB_DIRECTORY_FILE	"get_usb_directory_file"
#define CMD_USB_DELETE_FILE				"delete_usb_file"

// manage device
#define CMD_KEY_RESET               "reset"
#define CMD_KEY_REBOOT              "reboot"
#define CMD_KEY_IPERF3              "iperf3"
#define CMD_VAL_IPERF3_START        "start"
#define CMD_VAL_IPERF3_STOP         "stop"

//user password manage
//#define CMD_KEY_RESET_PASSWD      "reset_pwd"
#define CMD_KEY_RESET_USER_ID       "reset_pwd_user"
#define CMD_KEY_CHANGE_PASSWD       "change_pwd"
#define CMD_KEY_SHARE_PWD_FOR_APP   "share_pwd_for_app"

// bt download
#define CMD_KEY_GET_DOWNLOAD_STATUS "download_status"
#define CMD_KEY_ADD_TORRENT         "add_a_magnet"
#define CMD_KEY_DEL_TORRENT			"del_a_magnet"
#define CMD_KEY_START_DOWNLOAD		"start_download"
#define CMD_KEY_STOP_DOWNLOAD		"pause_download"
#define CMD_KEY_ADD_TORRENT_FILE	"add_a_seed"
#define CMD_KEY_GET_DOWNLOAD_FILE   "get_download_file"
#define CMD_GET_DOWNLOAD_FILE_RSE	"get_download_file_result"
//#define CMD_KEY_DEL_DOWNLOAD_FILE "delete_download"

// share
#define CMD_KEY_FILE_LIST               "file_list"
//#define CMD_KEY_GET_SHARE_STATUS 		"get_share_status"
#define CMD_KEY_GET_SHARE_DIRECTORY_FILE     "get_share_directory_file"
#define CMD_KEY_ADD_SHARE         		"add_share"
#define CMD_KEY_DELETE_SHARE      		"cancel_shared"
#define MSG_KEY_SHARE_RESULT	  		"add_share_status"
#define MSG_KEY_CANCEL_SHARE_RESULT 	"cancel_shared_status"
#define MSG_KEY_SHARE_FAIL_LIST	  		"add_shared_failed_files"
#define MSG_KEY_CANCEL_SHARE_FAIL_LIST 	"cancel_shared_failed_files"
//storage
#define CMD_GET_STOAGE_INFO      	"get_storage_info"
#define CMD_DEVICE_SPACE		 	"hard_disk_space"
#define CMD_REAMIN_SPACE			"hard_disk_remain"
#define CMD_DEVICE_STOAGE		 	"hard_disk_storage"
#define CMD_USER_STOAGE             "user_storage"
#define CMD_USER_NICKNAME			"user_nickname"
#define CMD_USB_SPACE         	 	"usb_space"
#define CMD_USB_STOAGE        	 	"usb_storage"
//database.
#define CMD_UPDATE_DATABASE         "update_user_database"
#define CMD_REPAIR_USER_DATABASE    "repair_user_database"
/** Index one uploaded file into user file.db. Value: path containing MyFiles/.../filename */
#define CMD_ADD_ONE_FILE            "add_one_file"
#define CMD_KEY_CHECK_FILE_EXISTS   "check_file_exists"
#define CMD_KEY_FILE_EXISTS         "file_exists"

#define CMD_SAVE_DEVICE_NAME	 	"save_app_device_name"
#define CMD_DEL_DEVICE_NAME		 	"del_app_device_name"
#define CMD_ADD_NEW_USER      	 	"add_new_user"
#define CMD_ADD_NEW_USER_PWD     	"add_new_user_pwd"
#define CMD_ADD_NEW_USER_RES		"add_new_user_result"
#define CMD_KEY_DELETE_USER		 	"delete_user"
#define CMD_DELETE_USER_RES		 	"delete_user_result"
#define CMD_KEY_REJECT_USER			"reject_user"
#define CMD_REJECT_USER_RES         "reject_user_result"
#define CMD_KEY_ALLOW_USER			"allow_user"
#define CMD_ALLOW_USER_RES          "allow_user_result"
#define CMD_KEY_MOVE_FILE			"app_move_file" //usb <--> disk
#define CMD_KEY_COPY_FILE			"app_copy_file" //usb <--> disk
  #define CMD_COPYING_FILE_STATUS	"copying_file_status" //reply copy status.
#define CMD_KEY_RENAME_FILE			"rename_file" 
#define CMD_KEY_FILE_RENAME			"file_rename" // "from", "to"
#define CMD_KEY_MOVE_FILES 			"move_files" // "from": "filePath_array", "to": "dest_sub_dir"(/MyFiles/xxx/xxx)
#define CMD_KEY_REMOVE_FILES		"remove_files"	//remove  corresponding files to recycle bin.
#define CMD_KEY_DOUBLE_DELETE_FILES "delete_files"	//delete corresponding files from recycle bin.
#define CMD_CURRENT_DIRECTORY		"current_directory"
#define CMD_KEY_DESTINATION_DIR		"destination_directory"
#define CMD_KEY_REPAIR_DISK         "repair_disk"
#define CMD_KEY_INIT_DISK           "init_disk"
#define CMD_KEY_FORMAT_DISK			"format_disk"
#define CMD_KEY_GET_HDD_FORMAT_TIME		"get_hdd_format_time"
  #define CMD_KEY_HDD_FORMAT_TIME		"hdd_format_time"
#define CMD_KEY_DEVICE_CFG_STATE	"dev_cfg_state"

#define CMD_KEY_CREATE_BACKUP       "create_file_backup"
#define CMD_KEY_RM_BACKUP           "remove_file_backup"
#define CMD_KEY_GET_BACKUP_LIST     "get_file_backup_list"

#define CMD_KEY_USER_DEL_DEV	 	"delete_device"
#define CMD_PARA_USER_DEL_DEV_RES 	"delete_device_result"
#define CMD_KEY_RECOVER_FILES		"recover_files"

#define CMD_KEY_MAKE_DIR        "make_directory"
#define CMD_KET_SUBDIR			"subdirectory_name"
//encrypted space
#define CMD_KEY_ENCRYPT_SPACE_STATUS "encrypt_space_status" //it's inclued  in "idevice_key_get_status" cmd.
#define CMD_SET_ENCRYPT_PWD    "set_encrypt_space_pwd"
#define CMD_LOGIN_ENCRYPT_SPACE    "login_encrypt_space"
#define CMD_CHANGE_ENCRYPT_PWD    "change_encrypt_space_pwd"
  #define CMD_ENCRYPT_PWD    		"encrypt_space_pwd"
	#define CMD_ENCRYPT_NEW_PWD    		"encrypt_space_new_pwd"
#define CMD_FORGET_ENCRYPT_PWD    "forget_encrypt_space_pwd"
#define CMD_RESET_ENCRYPT_PWD    "reset_encrypt_space_pwd"
#define CMD_GET_ENCRYPT_SPACE_FILES	"get_encrypt_space_files"
	#define CMD_ENCRYPT_SPACE_FILE_LIST "encrypt_space_file_list"
#define CMD_MOVE_INTO_ENCRYPT	"move_into_encrypt_space"
#define CMD_MOVE_OUT_ENCRYPT	"move_out_encrypt_space"

//save file original time
#define CMD_SET_FILE_TIME	"set_file_time"
#define CMD_SET_FILE_PATH	"file_path"

#define CMD_KEY_APP_MSG_FILE 		"app_msg_file"

#define CMD_KEY_APP_MSG_FILE 		"app_msg_file"
#define MSG_KEY_TYPE    "msg_type"
#define MSG_KEY_TYPE_STR   "string"
#define MSG_KEY_TYPE_FILE   "file"

//sys database file
#define USER_DB_DIR "DB"      /*  /mnt/sda1/Ftp/DB/  */
#define SYS_USER_CFG_DB			"/tmp/sys_user_db_web.cfg"
//table
#define  USER_PRESONAL_DATA_TABLE "system_user_tb"
#define  SMB_TABLE_NAME "samba_tb"
#define  FTP_TABLE_NAME "ftp_tb"
#define  PERMISSION_TABLE_NAME "permission_tb"
#define  NICKNAME_TABLE "nickname_tb"
//user's  DB of file storing.
#define  USER_FILE_DB "file.db"

typedef enum {
	CMD_ERROR = -2,
	DEAL_ERROR,
	CMD_OK,
	FILE_RECVING,
	FILE_EXISTED
} PARSE_APP_CMD_RET;

typedef struct {
	char name[64];
	off_t size;
	char path[128];				// Stored in nas device. 
	char md5[33];
} FILE_ATTRIBUTE_STRUCT;

struct list_file_name
{
	char name[256];
	struct list_file_name *next;
};

#define RES_OK "success"
#define RES_FAIL "fail"
#define RES_USER_EXISTS	"user_exists"

#define LISTEN_PORT 12345
#define MAXSIZE 4096
#define DEVICE_NAME_FILE_PATH "/tmp/device_name_web.cfg"
#define USER_FILE_THUMBANILS	"Thumbnails"
#define CURRENT_WORK_DIR	"MyFiles"
#define ENCRYPTED_SPACE_DIR "private_file" 

#define PRT_ERROR printf
#define PRT_DEBUG printf
#define TOKEN_LEN 16
#define NAS_MSG_FILE "nasmessage.txt"
#define APP_MSG_FILE "appmessage.txt"
#define MAX_PACKET_SIZE	 1024	//p2p connenct send max data length once.
#define MAX_MESG_RECV_SIZE 1024*1024	//1M.

enum LOGIN_RETURN_VALUE {
	LOGIN_FAIL_STATUS = -1,
	LOGIN_SUCCESS_STATUS,
	LOGIN_ADD_NEW_STATUS,
};

#endif
