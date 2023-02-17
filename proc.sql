use pos;

Alter table orderLine ADD unitPrice decimal(6,2);
Alter table orderLine ADD lineTotal decimal(7,2) AS (quantity * unitPrice);
Alter table `order` ADD orderTotal decimal(8,2);
Alter table customer drop column phone;
Alter table `order` drop FOREIGN KEY order_ibfk_1;
Alter table `order` drop FOREIGN KEY order_ibfk_2;
Alter table `order` drop column `status`;
drop table `status`;
Alter table `order` ADD FOREIGN KEY (customerID) REFERENCES customer(ID);


Delimiter //
create or replace procedure proc_FillUnitPrice()
Begin
    Update orderLine 
    inner join product 
    on orderLine.productID = product.ID 
    set unitPrice = currentPrice
    where unitPrice is null;
End //

Delimiter ;

Delimiter //
create or replace procedure proc_FillOrderTotal()
Begin
    Update `order` 
    set orderTotal = (select sum(lineTotal)
    from orderLine
    where orderLine.orderID = `order`.ID
    group by orderID);
End //

Delimiter ;

Delimiter //
create or replace procedure proc_FillMVCustomerPurchases()
Begin
    delete from mv_CustomerPurchases;
    insert into mv_CustomerPurchases 
    select * from v_CustomerPurchases;
End //

Delimiter ; 
