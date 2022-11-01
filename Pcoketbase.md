
# Pocketbase

It would be cool to perform type generation from a pocketbase schema to automatically generate a client

* endpoint - /api/collections?page=1&perPage=200&sort=%2Bcreated

```json
{
	"page": 1,
	"perPage": 200,
	"totalItems": 3,
	"totalPages": 1,
	"items": [
		{
			"id": "systemprofiles0",
			"created": "2022-10-27 04:51:12.991",
			"updated": "2022-10-27 04:51:12.991",
			"name": "profiles",
			"system": true,
			"schema": [
				{
					"system": true,
					"id": "pbfielduser",
					"name": "userId",
					"type": "user",
					"required": true,
					"unique": true,
					"options": {
						"maxSelect": 1,
						"cascadeDelete": true
					}
				},
				{
					"system": false,
					"id": "pbfieldname",
					"name": "name",
					"type": "text",
					"required": false,
					"unique": false,
					"options": {
						"min": null,
						"max": null,
						"pattern": ""
					}
				},
				{
					"system": false,
					"id": "pbfieldavatar",
					"name": "avatar",
					"type": "file",
					"required": false,
					"unique": false,
					"options": {
						"maxSelect": 1,
						"maxSize": 5242880,
						"mimeTypes": [
							"image/jpg",
							"image/jpeg",
							"image/png",
							"image/svg+xml",
							"image/gif"
						],
						"thumbs": null
					}
				}
			],
			"listRule": "userId = @request.user.id",
			"viewRule": "userId = @request.user.id",
			"createRule": "userId = @request.user.id",
			"updateRule": "userId = @request.user.id",
			"deleteRule": null
		},
		{
			"id": "oewqfnsrce7nqcn",
			"created": "2022-10-27 08:01:31.593",
			"updated": "2022-10-27 08:01:31.593",
			"name": "test_machine",
			"system": false,
			"schema": [
				{
					"system": false,
					"id": "clhhoek4",
					"name": "name",
					"type": "text",
					"required": true,
					"unique": false,
					"options": {
						"min": null,
						"max": null,
						"pattern": ""
					}
				},
				{
					"system": false,
					"id": "ftg9ambk",
					"name": "machine_mac",
					"type": "text",
					"required": true,
					"unique": true,
					"options": {
						"min": null,
						"max": null,
						"pattern": ""
					}
				},
				{
					"system": false,
					"id": "2mrcxr0j",
					"name": "project",
					"type": "text",
					"required": true,
					"unique": false,
					"options": {
						"min": null,
						"max": null,
						"pattern": ""
					}
				},
				{
					"system": false,
					"id": "vaomnrmg",
					"name": "version",
					"type": "text",
					"required": true,
					"unique": false,
					"options": {
						"min": null,
						"max": null,
						"pattern": ""
					}
				}
			],
			"listRule": null,
			"viewRule": null,
			"createRule": null,
			"updateRule": null,
			"deleteRule": null
		},
		{
			"id": "xemp306w8jybdv2",
			"created": "2022-10-27 08:01:31.593",
			"updated": "2022-10-27 08:01:31.593",
			"name": "agdtester_c_summary",
			"system": false,
			"schema": [
				{
					"system": false,
					"id": "i8u9h5pw",
					"name": "test_machine_id",
					"type": "relation",
					"required": false,
					"unique": false,
					"options": {
						"maxSelect": 0,
						"collectionId": "test_machine",
						"cascadeDelete": false
					}
				},
				{
					"system": false,
					"id": "6gsfbgf3",
					"name": "batch_no",
					"type": "text",
					"required": true,
					"unique": false,
					"options": {
						"min": null,
						"max": null,
						"pattern": ""
					}
				},
				{
					"system": false,
					"id": "r3j2ltl6",
					"name": "serial_no",
					"type": "text",
					"required": false,
					"unique": false,
					"options": {
						"min": null,
						"max": null,
						"pattern": ""
					}
				},
				{
					"system": false,
					"id": "dfverw80",
					"name": "raw_data",
					"type": "file",
					"required": false,
					"unique": false,
					"options": {
						"maxSelect": 0,
						"maxSize": 0,
						"mimeTypes": [
							"application/json"
						],
						"thumbs": null
					}
				},
				{
					"system": false,
					"id": "cjjwmbo3",
					"name": "passed",
					"type": "bool",
					"required": false,
					"unique": false,
					"options": {}
				},
				{
					"system": false,
					"id": "zp52sxe3",
					"name": "error",
					"type": "text",
					"required": false,
					"unique": false,
					"options": {
						"min": null,
						"max": null,
						"pattern": ""
					}
				},
				{
					"system": false,
					"id": "bhlr6xwa",
					"name": "loaded_current_mA",
					"type": "number",
					"required": false,
					"unique": false,
					"options": {
						"min": null,
						"max": null
					}
				},
				{
					"system": false,
					"id": "jobevs5k",
					"name": "loaded_current_mA_passed",
					"type": "bool",
					"required": false,
					"unique": false,
					"options": {}
				},
				{
					"system": false,
					"id": "s37n64pj",
					"name": "unloaded_current_mA",
					"type": "number",
					"required": false,
					"unique": false,
					"options": {
						"min": null,
						"max": null
					}
				},
				{
					"system": false,
					"id": "mpegl3qw",
					"name": "unloaded_current_mA_passed",
					"type": "bool",
					"required": false,
					"unique": false,
					"options": {}
				},
				{
					"system": false,
					"id": "dwv6oinw",
					"name": "loaded_voltage_mV",
					"type": "number",
					"required": false,
					"unique": false,
					"options": {
						"min": null,
						"max": null
					}
				},
				{
					"system": false,
					"id": "d9yziem9",
					"name": "loaded_voltage_mV_passed",
					"type": "bool",
					"required": false,
					"unique": false,
					"options": {}
				},
				{
					"system": false,
					"id": "r9waqcgn",
					"name": "unloaded_voltage_mV",
					"type": "number",
					"required": false,
					"unique": false,
					"options": {
						"min": null,
						"max": null
					}
				},
				{
					"system": false,
					"id": "iy8sdoei",
					"name": "unloaded_voltage_mV_passed",
					"type": "bool",
					"required": false,
					"unique": false,
					"options": {}
				},
				{
					"system": false,
					"id": "pfhaadql",
					"name": "loaded_rpm",
					"type": "number",
					"required": false,
					"unique": false,
					"options": {
						"min": null,
						"max": null
					}
				},
				{
					"system": false,
					"id": "8g5qysek",
					"name": "loaded_rpm_passed",
					"type": "bool",
					"required": false,
					"unique": false,
					"options": {}
				},
				{
					"system": false,
					"id": "fbngluq6",
					"name": "unloaded_rpm",
					"type": "number",
					"required": false,
					"unique": false,
					"options": {
						"min": null,
						"max": null
					}
				},
				{
					"system": false,
					"id": "xfjj0dk5",
					"name": "unloaded_rpm_passed",
					"type": "bool",
					"required": false,
					"unique": false,
					"options": {}
				},
				{
					"system": false,
					"id": "qtzuwrrk",
					"name": "loaded_torque_mNm",
					"type": "number",
					"required": false,
					"unique": false,
					"options": {
						"min": null,
						"max": null
					}
				},
				{
					"system": false,
					"id": "whfuyaef",
					"name": "loaded_torque_mNm_passed",
					"type": "bool",
					"required": false,
					"unique": false,
					"options": {}
				},
				{
					"system": false,
					"id": "bs9gwtza",
					"name": "unloaded_torque_mNm",
					"type": "number",
					"required": false,
					"unique": false,
					"options": {
						"min": null,
						"max": null
					}
				},
				{
					"system": false,
					"id": "xhhdwbnw",
					"name": "unloaded_torque_mNm_passed",
					"type": "bool",
					"required": false,
					"unique": false,
					"options": {}
				}
			],
			"listRule": null,
			"viewRule": null,
			"createRule": null,
			"updateRule": null,
			"deleteRule": null
		}
	]
}


```
