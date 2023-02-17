use pos;

call proc_FillUnitPrice();
call proc_FillOrderTotal();
call proc_FillMVCustomerPurchases();

create table priceChangeLog (
    ID int UNSIGNED AUTO_INCREMENT,
    oldPrice decimal(6,2),
    newPrice decimal(6,2),
    changeTimestamp Timestamp,
    productid int,
    PRIMARY KEY (ID),
    FOREIGN KEY(productid) REFERENCES product(ID)
    )Engine=InnoDB;


create table priceChange (
    ID int UNSIGNED,
    oldPrice decimal(6,2),
    newPrice decimal(6,2),
    changeTimestamp Timestamp,
    productid int,
    FOREIGN KEY(productid) REFERENCES product(ID)
    )Engine=InnoDB;

Delimiter //
create or replace trigger before_price_update
after update on product /* works with before update as well */
for each row 
Begin
    if new.currentPrice <> old.currentPrice 
    then 
    insert into priceChangeLog(oldPrice, newPrice, productid)
    values (old.currentPrice,new.currentPrice, new.ID);
    end if;
    call mv_product(new.ID);
End; //

Delimiter ;

Delimiter //
create or replace trigger before_newprice_insert
before insert on orderLine
for each row 
Begin
    set new.unitPrice = (select product.currentPrice from product
    where new.productID = product.ID );  
     if new.quantity is NULL then 
        set new.quantity = 1;
    end if;
End; //
Delimiter ;

Delimiter //
create or replace trigger before_newprice_update
before update on orderLine
for each row 
Begin
    set new.unitPrice = (select product.currentPrice from product
    where new.productID = product.ID );  
     if new.quantity is NULL then 
        set new.quantity = 1;
    end if;
End; //
Delimiter ;


Delimiter //
create or replace trigger after_orderLine_insert
after insert on orderLine
for each row
Begin
    Update `order` 
    set orderTotal = (select sum(lineTotal)
    from orderLine
    where orderLine.orderID = `order`.ID)
    where ID = new.orderID ;
End; //
Delimiter ;

Delimiter //
create or replace trigger after_orderLine_update
after update on orderLine
for each row
Begin
    Update `order` 
    set orderTotal = (select sum(lineTotal)
    from orderLine
    where orderLine.orderID = `order`.ID)
    where ID = new.orderID ;
End; //
Delimiter ;

Delimiter //
create or replace trigger after_orderLine_delete
after delete on orderLine
for each row
Begin
    Update `order` 
    set orderTotal = (select sum(lineTotal)
    from orderLine
    where orderLine.orderID = `order`.ID)
    where ID = old.orderID ;
End; //
Delimiter ;

Delimiter //
create or replace procedure mv_product(IN prod int)
Begin
delete from mv_ProductBuyers where mv_ProductBuyers.productID = prod;
insert into mv_ProductBuyers  
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
where productID = prod
group by p.ID;
End //
Delimiter ; 

Delimiter //
create or replace procedure mv_customer(IN cust int) 
Begin
delete from mv_CustomerPurchases where mv_CustomerPurchases.ID = cust;
insert into mv_CustomerPurchases 
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
where c.ID = cust
group by c.ID;
End //
Delimiter ; 


Delimiter //
create or replace trigger after_allmv_insert
after insert on orderLine
for each row
Begin
    declare cust int;
    set @cust = (select `order`.customerID from `order` 
    where order.ID = new.orderID);
    call mv_customer(@cust);
    call mv_product(new.productID);
End; //
Delimiter ;


Delimiter //
create or replace  trigger after_allmv_update
after update on orderLine
for each row
Begin
    declare cust int;
    set @cust = (select `order`.customerID from `order` 
    where order.ID = new.orderID);
    call mv_customer(@cust);
    call mv_product(new.productID);
End; //
Delimiter ;

Delimiter //
create or replace trigger after_allmv_delete
after delete on orderLine
for each row
Begin
    declare cust int;
    set @cust = (select `order`.customerID from `order` 
    where order.ID = old.orderID);
    call mv_customer(@cust);
    call mv_product(old.productID);
End; //
Delimiter ;



/*Delimiter //
create trigger after_mvprod_insert
after insert on orderLine
for each row
Begin
    call mv_product(new.productID);
End; //
Delimiter ;

Delimiter //
create trigger after_mvprod_update
after update on orderLine
for each row
Begin
    call mv_product(new.productID);
End; //
Delimiter ;

Delimiter //
create trigger after_mvprod_delete
after delete on orderLine
for each row
Begin
    call mv_product(old.productID);
End; //
Delimiter ;
*/


/*Delimiter //
create or replace trigger qty_insert
before insert on orderLine
for each row
Begin
    if new.quantity is NULL then 
        set new.quantity = 1;
    end if;
End; //
Delimiter ; */

Delimiter //
create or replace trigger qty_afterinsert
after insert on orderLine
for each row
Begin
set @qty = (select product.qtyOnHand from product where product.ID = new.productID);
    if new.quantity < @qty then
    update product
    set product.qtyOnHand = product.qtyOnHand - new.quantity
    where product.ID = new.productID;
    else 
        signal sqlstate '45000' set message_text = 'Not enough available';
    end if;
End; //
Delimiter ; 

/*Delimiter //
create or replace trigger qty_update
before update on orderLine
for each row
Begin
    if new.quantity is NULL then 
        set new.quantity = 1;
    end if;
End; //
Delimiter ; */

Delimiter //
create or replace trigger qty_after_update
after update on orderLine
for each row
Begin
set @qty = (select product.qtyOnHand from product where product.ID = new.productID);
set @net = (new.quantity - old.quantity);
    if @net < @qty then
    update product 
    set product.qtyOnHand = product.qtyOnHand - @net
    where product.ID = new.productID;
    else
        signal sqlstate '45000' set message_text = 'Not enough available';
    end if;
End; //
Delimiter ; 

Delimiter //
create or replace trigger qty_after_delete
after delete on orderLine
for each row
Begin
/*set @qty = (select product.qtyOnHand from product where product.ID = old.productID);*/
    update product 
    set product.qtyOnHand = product.qtyOnHand + old.quantity
    where product.ID = old.productID;
    
End; //
Delimiter ; 