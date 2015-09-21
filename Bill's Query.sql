SELECT

/* Order Information */

	orders.id AS "Order ID",
	clients_statement.id AS "Statement Number",
	DATE_FORMAT (ordereddate,"%m/%d/%Y") as "Order Date",
	order_types.`descrip` as "Product",
	`propertyaddress` as "Property Address",
	`propertyaddress2` as "Property Address 2",
	`propertycity` AS "Property City",
	`propertystate` AS "Property State",
	`propertyzipcode` AS "Property Zip Code",
	ROUND((((unix_timestamp(qcchecklist_complete.dts)) - (unix_timestamp(ordereddate)))/86400),2) AS "Turn Time (days)",
	DATE_FORMAT (qcchecklist_complete.dts, "%m/%d/%Y") AS "Client Delivery Date",
	clients.client_name AS "Client Name",
	CONCAT (user_data_client.firstname," ",user_data_client.lastname) AS "Ordered By",
	clients.`comp_name` AS "Company Name",
	clients.`address_1` AS "Client Address 1",
	clients.`address_2` AS "Client Address 2",
	clients.`city` AS "Client City",
	clients.state AS "Client State",
	clients.`zipcode` AS "Client Zipcode",
	orders.`invoiceamount` AS "Invoice Amount",
	
	
/* Agent/Inspector Information */	
	
	CASE WHEN (inspection_parts.acceptedby is Null) THEN "" ELSE inspection_parts.acceptedby END AS "Agent Vendor ID",
	CASE WHEN (inspection_vendor.tax_fullname is Null) THEN "" ELSE inspection_vendor.tax_fullname END AS "Agent W9 Full Name",
	CASE WHEN (inspection_vendor.tax_company is Null) THEN "" ELSE inspection_vendor.tax_company END AS "Agent W9 Company",
	CASE WHEN (inspection_vendor.tax_address is Null) THEN "" ELSE inspection_vendor.tax_address END AS "Agent W9 Address",
	CASE WHEN (inspection_vendor.tax_city is Null) THEN "" ELSE inspection_vendor.tax_city END AS "Agent W9 City",
	CASE WHEN (inspection_vendor.tax_state is Null) THEN "" ELSE inspection_vendor.tax_state END AS "Agent W9 State",
	CASE WHEN (inspection_vendor.tax_zipcode is Null) THEN "" ELSE inspection_vendor.tax_zipcode END AS "Agent W9 Zip Code",
	CASE WHEN (inspection_parts.vendorfee is Null) THEN "" ELSE inspection_parts.vendorfee END AS "Agent Vendor Fee",

/* Appraiser Information */
	
	gear_parts.acceptedby AS "Appraiser Vendor ID",
	CONCAT (gear_vendor.firstname," ",gear_vendor.lastname) AS "Assigned Appraiser",
	CASE WHEN (parent_vendor.userid is Null) THEN CONCAT(gear_vendor.firstname," ",gear_vendor.lastname) ELSE CONCAT(parent_vendor.firstname," ",parent_vendor.lastname) END AS 'Company Owner/Zone Licensee',
	CASE WHEN (parent_vendor.userid is Null) THEN gear_vendor.tax_company ELSE parent_vendor.tax_company END AS 'W9 Appraisal Company',
	CASE WHEN (parent_vendor.userid is Null) THEN gear_vendor.tax_address ELSE parent_vendor.tax_address END AS 'W9 Appraisal Company Address',
	CASE WHEN (parent_vendor.userid is Null) THEN gear_vendor.tax_city ELSE parent_vendor.tax_city END AS 'A9 Appraisal Company City',
	CASE WHEN (parent_vendor.userid is Null) THEN gear_vendor.tax_state ELSE parent_vendor.tax_state END AS 'W9 Appraisal Company State',
	CASE WHEN (parent_vendor.userid is Null) THEN gear_vendor.tax_zipcode ELSE parent_vendor.tax_zipcode END AS 'W9 Appraisal Company Zip Code',
	gear_parts.vendorfee AS 'Appraiser Vendor Fee',
	
/* Data Payment Column */

	CASE WHEN (zreport_key > 0 AND order_types.id != 45) THEN "Yes" ELSE "" END AS "Zone Data Fee",
	`gear_parts`.`gear_manual_status` AS "GEAR METHOD"


FROM
	orders
	INNER JOIN order_parts as gear_parts ON (orders.id=gear_parts.orderid AND gear_parts.part_type IN (12,5))
	LEFT JOIN order_parts as inspection_parts ON (orders.id=inspection_parts.orderid AND inspection_parts.part_type NOT IN (12,5,9))
	LEFT JOIN user_data_vendor as gear_vendor ON (gear_parts.acceptedby = gear_vendor.userid)
	LEFT JOIN user_data_vendor as parent_vendor ON (gear_vendor.parent_user = parent_vendor.userid)
	LEFT JOIN user_data_vendor as inspection_vendor ON (inspection_parts.acceptedby = inspection_vendor.userid)
	JOIN order_types ON (orders.order_type = order_types.id)
	JOIN user_data_client ON (orders.orderbyid = user_data_client.userid)
	JOIN clients ON (user_data_client.clientid = clients.id)
	JOIN (SELECT orderid, MIN(qcchecklist_complete.dts) as dts FROM `qcchecklist_complete` GROUP BY orderid ) AS qcchecklist_complete ON (qcchecklist_complete.orderid = orders.id)
	LEFT JOIN client_transactions ON (orders.id = client_transactions.orderid AND type="COMPLETED")
	LEFT JOIN `clients_statement` ON (FIND_IN_SET(client_transactions.id, transactions))


	
WHERE
	orders.companyid= 2 AND
	orders.order_type != 45 AND
	orders.id IN (SELECT DISTINCT orderid FROM `qcchecklist_complete` WHERE qcchecklist_complete.`dts` >= "2015-2-01 00:00:00" AND qcchecklist_complete.`dts` <= "2015-2-28 00:00:00")
	/*orders.order_status IN(10,7,14)*/
	
UNION

SELECT

/* Order Information */

	orders.id AS "Order ID",
	clients_statement.id AS "Statement Number",
	DATE_FORMAT (ordereddate,"%m/%d/%Y") as "Order Date",
	order_types.`descrip` as "Product",
	`propertyaddress` as "Property Address",
	`propertyaddress2` as "Property Address 2",
	`propertycity` AS "Property City",
	`propertystate` AS "Property State",
	`propertyzipcode` AS "Property Zip Code",
	ROUND((((unix_timestamp(qcchecklist_complete.dts)) - (unix_timestamp(ordereddate)))/86400),2) AS "Turn Time (days)",
	DATE_FORMAT (qcchecklist_complete.dts, "%m/%d/%Y") AS "Client Delivery Date",
	clients.client_name AS "Client Name",
	CONCAT (user_data_client.firstname," ",user_data_client.lastname) AS "Ordered By",
	clients.`comp_name` AS "Company Name",
	clients.`address_1` AS "Client Address 1",
	clients.`address_2` AS "Client Address 2",
	clients.`city` AS "Client City",
	clients.state AS "Client State",
	clients.`zipcode` AS "Client Zipcode",
	orders.`invoiceamount` AS "Invoice Amount",
	
	
/* Agent/Inspector Information */	
	
	CASE WHEN (order_parts.acceptedby is Null) THEN "" ELSE order_parts.acceptedby END AS "Agent Vendor ID",
	CASE WHEN (inspection_vendor.tax_fullname is Null) THEN "" ELSE inspection_vendor.tax_fullname END AS "Agent W9 Full Name",
	CASE WHEN (inspection_vendor.tax_company is Null) THEN "" ELSE inspection_vendor.tax_company END AS "Agent W9 Company",
	CASE WHEN (inspection_vendor.tax_address is Null) THEN "" ELSE inspection_vendor.tax_address END AS "Agent W9 Address",
	CASE WHEN (inspection_vendor.tax_city is Null) THEN "" ELSE inspection_vendor.tax_city END AS "Agent W9 City",
	CASE WHEN (inspection_vendor.tax_state is Null) THEN "" ELSE inspection_vendor.tax_state END AS "Agent W9 State",
	CASE WHEN (inspection_vendor.tax_zipcode is Null) THEN "" ELSE inspection_vendor.tax_zipcode END AS "Agent W9 Zip Code",
	CASE WHEN (order_parts.vendorfee is Null) THEN "" ELSE order_parts.vendorfee END AS "Agent Vendor Fee",

/* Appraiser Information */
	
	order_parts.acceptedby AS "Appraiser Vendor ID",
	CONCAT (gear_vendor.firstname," ",gear_vendor.lastname) AS "Assigned Appraiser",
	CASE WHEN (parent_vendor.userid is Null) THEN CONCAT(gear_vendor.firstname," ",gear_vendor.lastname) ELSE CONCAT(parent_vendor.firstname," ",parent_vendor.lastname) END AS 'Company Owner/Zone Licensee',
	CASE WHEN (parent_vendor.userid is Null) THEN gear_vendor.tax_company ELSE parent_vendor.tax_company END AS 'W9 Appraisal Company',
	CASE WHEN (parent_vendor.userid is Null) THEN gear_vendor.tax_address ELSE parent_vendor.tax_address END AS 'W9 Appraisal Company Address',
	CASE WHEN (parent_vendor.userid is Null) THEN gear_vendor.tax_city ELSE parent_vendor.tax_city END AS 'W9 Appraisal Company City',
	CASE WHEN (parent_vendor.userid is Null) THEN gear_vendor.tax_state ELSE parent_vendor.tax_state END AS 'W9 Appraisal Company State',
	CASE WHEN (parent_vendor.userid is Null) THEN gear_vendor.tax_zipcode ELSE parent_vendor.tax_zipcode END AS 'W9 Appraisal Company Zip Code',
	order_parts.vendorfee AS 'Appraiser Vendor Fee',
	
/* Data Payment Column */

	CASE WHEN (zreport_key > 0 AND order_types.id != 45) THEN "Yes" ELSE "" END AS "Zone Data Fee",
	" " AS "GEAR METHOD"


FROM
	orders
	INNER JOIN order_parts ON (orders.id=order_parts.orderid AND order_parts.part_type IN (9))
	LEFT JOIN user_data_vendor as gear_vendor ON (order_parts.acceptedby = gear_vendor.userid AND gear_vendor.vendor_types=4)
	LEFT JOIN user_data_vendor as parent_vendor ON (gear_vendor.parent_user = parent_vendor.userid AND gear_vendor.vendor_types=4)
	LEFT JOIN user_data_vendor as inspection_vendor ON (order_parts.acceptedby = inspection_vendor.userid AND inspection_vendor.vendor_types!=4)
	JOIN order_types ON (orders.order_type = order_types.id)
	JOIN user_data_client ON (orders.orderbyid = user_data_client.userid)
	JOIN clients ON (user_data_client.clientid = clients.id)
	LEFT JOIN (SELECT orderid, MIN(qcchecklist_complete.dts) as dts FROM `qcchecklist_complete` GROUP BY orderid ) AS qcchecklist_complete ON (qcchecklist_complete.orderid = orders.id)
	LEFT JOIN client_transactions ON (orders.id = client_transactions.orderid AND type="COMPLETED")
	LEFT JOIN `clients_statement` ON (FIND_IN_SET(client_transactions.id, transactions))

	
WHERE
	orders.companyid=2 AND
	orders.id IN (SELECT DISTINCT orderid FROM order_parts WHERE order_parts.`effective_date` >= "2015-2-01 00:00:00" AND order_parts.`effective_date` <= "2015-2-28 00:00:00" AND part_type=9)
	/*orders.order_status IN (10,7,14) */
