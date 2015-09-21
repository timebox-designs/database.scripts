# There are 27 Solution Star related companies

# SELECT
#   c.id
#   , c.comp_name
# FROM clients c
# WHERE comp_name LIKE 'SOLUTION%'
# ORDER BY 2
# ;
#
# # Solution Star Users
#
# SELECT
#   c.comp_name 'Company Name'
#   , CONCAT_WS(' ', u.firstname, u.lastname) 'User Name'
# FROM clients c
#   JOIN user_data_client u ON c.id = u.clientid
# WHERE c.id IN
#       (163, 166, 167, 168, 169, 178, 187, 271, 313, 314, 315, 316, 317, 318, 319, 320, 321, 323, 324, 325, 326, 327, 328, 329, 330, 331, 332)
# ORDER BY 1
# ;

# Solution Star Remittance

# SELECT
#   o.partner_reference_num 'Gator ID'
#   , UPPER(CONCAT_WS(', ', TRIM(o.propertyaddress), o.propertycity, o.propertystate, o.propertyzipcode)) 'Address'
#   , s.id 'Statement No.'
#   , s.statement_date 'Statement Date'
#   , c.client_name 'Client Name'
#   , o.id 'Order No.'
#   , DATE(o.ordereddate) 'Order Date'
#   , DATE(t.dts) 'Delivery Date'
#   , o.invoiceamount 'Invoice Amount'
# FROM orders o
#   JOIN client_transactions t ON t.orderid = o.id
#   JOIN clients c ON c.id = t.clientid
#   JOIN clients_statement s ON FIND_IN_SET(t.id, s.transactions)
#   JOIN
#   (
#
#   ) x ON x.id = o.partner_reference_num
# WHERE t.type = 'COMPLETED'
# ORDER BY 1
# ;


SELECT
  o.loanreference 'Ref No.'
  , UPPER(CONCAT_WS(', ', TRIM(o.propertyaddress), o.propertycity, o.propertystate, o.propertyzipcode)) 'Address'
  , s.id 'Statement No.'
  , s.statement_date 'Statement Date'
  , c.client_name 'Client Name'
  , o.id 'Order No.'
  , DATE(o.ordereddate) 'Order Date'
  , DATE(t.dts) 'Delivery Date'
  , o.invoiceamount 'Invoice Amount'
FROM orders o
  JOIN client_transactions t ON t.orderid = o.id
  JOIN clients c ON c.id = t.clientid
  JOIN clients_statement s ON FIND_IN_SET(t.id, s.transactions)
  JOIN (
    ) x ON x.id = o.loanreference
WHERE o.partner_reference_num IS NULL
;

# SELECT
#     o.partner_reference_num 'Gator ID'
#   , UPPER(CONCAT_WS(', ', TRIM(o.propertyaddress), o.propertycity, o.propertystate, o.propertyzipcode)) 'Address'
#   , 'na' AS 'Statement No.'
#   , 'na' AS 'Statement Date'
#   , c.client_name 'Client Name'
#   , o.id 'Order No.'
#   , DATE(o.ordereddate) 'Order Date'
#   , 'na' AS 'Delivery Date'
#   , o.invoiceamount 'Invoice Amount'
# FROM orders o
#   JOIN user_data_client u ON u.userid = o.orderbyid
#   JOIN clients c ON c.id = u.clientid
# WHERE o.partner_reference_num = '12-02531095'
# ;
# 

