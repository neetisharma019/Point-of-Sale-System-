use pos;

create or replace view v_JsonView as 
select o.ID, od.quantity, od.unitPrice, od.lineTotal, p.`name`
from `order` as o
left join
orderLine as od 
on o.ID = od.orderID
left join
product as p 
on od.productID = p.ID;

select json_object("CustomerName", CONCAT(firstName," ", lastName), "Email", email, "Orders", json_arrayagg(json_object("Order Total", `order`.orderTotal, "Date Placed",`order`.datePlaced, "Date Shipped", `order`.dateShipped,
"Products",( select json_arrayagg(json_object("Name", v_JsonView.`name`, "Quantity", v_JsonView.quantity, "UnitPrice", v_JsonView.unitPrice )) from v_JsonView where v_JsonView.ID = `order`.ID group by `order`.ID) 
)))
from customer
left join `order`on customer.ID = `order`.customerID
group by customer.ID into outfile 'Customers.json';  