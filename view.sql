use pos;

create or replace view v_CustomerNames as 
select lastName as LN, firstName as FN
from customer
order by lastName, firstName;

create or replace view v_Customers as
select c.ID as customer_number, c.firstName as first_name, c.lastName as last_name, c.address1 as street1, c.address2 as street2, ct.`city`, ct.`state`, c.zip as zip_code, c.`email`
from customer as c 
inner join
city as ct
on c.zip = ct.zip;

create or replace view v_ProductBuyers  as
select p.ID as productID, p.`name` as productName, GROUP_CONCAT(distinct c.ID,' ',c.firstName,' ',c.lastName order by c.ID SEPARATOR ',') as customers
from product as p
left join
orderLine as od
on p.ID = od.productID
left join
`order` as o
on od.orderID = o.ID
left join 
customer as c
on o.customerID = c.ID
group by p.ID;

create or replace view v_CustomerPurchases as 
select c.ID, c.firstName, c.lastName, GROUP_CONCAT(distinct p.ID,' ',p.`name` order by p.ID SEPARATOR'|') as products
from customer as c
left join
`order` as o
on c.ID = o.customerID
left join
orderLine as od
on o.ID = od.orderID
left join
product as p 
on od.productID = p.ID
group by c.ID;

create table mv_ProductBuyers Engine=InnoDB as
select * from v_ProductBuyers;

create table mv_CustomerPurchases Engine=InnoDB as
select * from v_CustomerPurchases;

create index idx_CustomerEmail  
on customer (email);

create index idx_ProductName
on product (`name`);


 
 
 
 
 
 
 
 
 
 
 
 
 
 select json_object ('name', concat( firstName," ", lastName)) from customer where ID = 1;
 select cust.ID as customersID, o.ID, count(cust.ID) from customer as cust left join `order`as o on cust.ID = customerID group by cust.ID having count(cust.ID)>3;
 DELIMITER ;;

CREATE or replace PROCEDURE JsonData()
BEGIN
DECLARE n INT DEFAULT 0;
DECLARE i INT DEFAULT 0;
/*SELECT COUNT(ID) FROM customer INTO n;*/
/*SET i=0;*/
/*WHILE i<n DO  */
  create or replace view v_JsonData as
  select json_object("CustomerName", CONCAT(firstName," ", lastName),"Orders", json_arrayagg(json_object("OrdersID", `order`.ID, 
  "Products",( select json_arrayagg(json_object("Name", v_JsonView.`name`, "Quantity", v_JsonView.quantity, "Price", v_JsonView.unitPrice)) from v_JsonView where v_JsonView.ID = `order`.ID group by `order`.ID) 
  )))
  from customer
  join `order`on customer.ID = `order`.customerID
  group by customer.ID; 
 
  
  /*SET i = i + 1;*/
/*END WHILE;*/
select * from v_JsonData into outfile '/Users/neetisharma/Desktop/ew.json';
End;;
DELIMITER ;

/*Delimiter ;;
create or replace procedure newData()
Begin
set @sql = concat ('select customer.ID from customer, INTO OUTFILE "new' ,ID,' .json"'
'FIELDS TERMINATED BY "}"' 'ENCLOSED BY' '"' 'LINES TERMINATED BY' "\n");
prepare stmt1 from @sql;
execute stmt1;
deallocate prepare stmt1;
End ;;
Delimiter ;*/



Delimiter ;;
create or replace procedure newData()
Begin
    set @sql = call ROWPERROW() INTO OUTFILE 'new.json';
prepare stmt1 from @sql;
execute stmt1;
deallocate prepare stmt1;
End ;;
Delimiter ;


select json_object("Name", CONCAT(firstName," ", lastName),"Orders", json_arrayagg(json_object("OrdersID", `order`.ID, 
"Products",( select json_arrayagg(json_object("Name", v_JsonView.`name`, "Quantity", v_JsonView.quantity, "Price", v_JsonView.unitPrice)) from v_JsonView where v_JsonView.ID = `order`.ID group by `order`.ID) 
)))
from customer
join `order`on customer.ID = `order`.customerID 
group by customer.ID;

DELIMITER $$
CREATE PROCEDURE createCustomerList(
	INOUT customerlist varchar(4000)
)
BEGIN
	DECLARE finished INTEGER DEFAULT 0;
	DECLARE cust varchar(255) DEFAULT "";

	
	DEClARE curCustomer 
		CURSOR FOR 
			SELECT json_object('Name', CONCAT(firstName,"", lastName),'orders', json_arrayagg(json_object('orderID', `order`.ID))) from customer join `order`on customer.ID = `order`.customerID where customer.ID = 1;


	DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET finished = 1;

	OPEN curCustomer;

	getCustomer: LOOP
		FETCH curCustomer INTO cust;
		IF finished = 1 THEN 
			LEAVE getCustomer;
		END IF;
		
		SET customerlist = CONCAT(cust,";",customerlist);
	END LOOP getCustomer;
	CLOSE curCustomer;

END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS cursor_ROWPERROW;
DELIMITER ;;

CREATE PROCEDURE cursor_ROWPERROW()
BEGIN
 
  DECLARE cursor_ID INT;
  /*DECLARE cursor_VAL VARCHAR(255);
  DECLARE order_ID INT;
  DECLARE new_ID INT;*/
  DECLARE done INT DEFAULT FALSE;
  DECLARE cursor_i CURSOR FOR SELECT json_object('Name', CONCAT(firstName,"", lastName),'orders', json_arrayagg(json_object('orderID', `order`.ID))) from customer join `order`on customer.ID = `order`.customerID  ;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
  OPEN cursor_i;
  read_loop: LOOP
    FETCH cursor_i INTO cursor_ID;
    IF done THEN
      LEAVE read_loop;
    END IF;

  END LOOP;
  CLOSE cursor_i;

END;;
DELIMITER ;

/*select json_object('Name', CONCAT(firstName,"", lastName),'orders', json_arrayagg
(json_object('ordersID', `order`.ID)), 'products', json_arrayagg (json_object ('productID', product.ID))
) from product join orderLine on product.ID = orderLine.productID join `order` on orderLine.orderID = `order`.ID join customer on`order`.customerID = customer.ID where customer.ID=1;

join v_New
on `order`.ID = v_New.ID
where customer.ID = 1;

(select `name`, jsonb_agg (vnew) 'Totalorders' from v_New group by `name`) vnew
on vnew.ID = `order`.ID;


select json_object('OrdersID', `order`.ID,'Products',json_arrayagg(json_object('Name', v_New.`name`)) )
from `order` join v_New on `order`.ID = v_New.ID where `order`.ID=1;

select json_object('Name', CONCAT(firstName,"", lastName),'orders', json_arrayagg(json_object('orderID', `order`.ID, 'Products',json_arrayagg(json_object('Name', v_New.`name`)))))
rom customer join `order`on customer.ID = `order`.customerID join v_New on `order`.ID = v_New.ID where customer.ID=1 group by ;*/


DELIMITER ;;
CREATE or replace PROCEDURE JsonData()
BEGIN
  create or replace view v_JsonData as
  select json_object("CustomerName", CONCAT(firstName," ", lastName),"Orders", json_arrayagg(json_object("OrdersID", `order`.ID, "Date Placed",`order`.datePlaced, "Date Shipped", `order`.dateShipped,
  "Products",( select json_arrayagg(json_object("Name", v_JsonView.`name`, "Quantity", v_JsonView.quantity, "UnitPrice", v_JsonView.unitPrice, "LineTotal", v_JsonView.lineTotal)) from v_JsonView where v_JsonView.ID = `order`.ID group by `order`.ID) 
  )))
  from customer
  left join `order`on customer.ID = `order`.customerID
  group by customer.ID; 
 
/*select * from v_JsonData into outfile '/Users/neetisharma/Desktop/Customers.json';*/
select * from v_JsonData into outfile 'Data.json';
End;;
DELIMITER ;