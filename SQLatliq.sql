use retail_events_db
select * from dim_stores
select * from dim_campaigns
select * from fact_events$
INSERT INTO dim_campaigns VALUES ('CAMP_DIW_01','Diwali','2023-11-12','2023-11-18'),('CAMP_SAN_01','Sankranti','2024-01-10','2024-01-16');


---------products with base_price greater than 500

select distinct(p.product_name),f.base_price 
from fact_events$ f 
join dim_products p on 
f.product_code=p.product_code
where promo_type='BOGOF' and base_price>500


---------total number of stores per city in decreasing order

select city , count(store_id)  as store_count 
from dim_stores 
group by (city) 
order by store_count desc 

------Top 5 Products by IR_REV_PER-------

with cte1 as
(
select
     c.campaign_id,f.product_code,
CASE
      WHEN promo_type='50% OFF' then (0.5*base_price)
      WHEN promo_type='25% OFF' then (base_price*(1-0.25))
      WHEN promo_type='33% OFF' then base_price*(1-0.33)
      WHEN promo_type='500 Cashback' then (base_price-500)
      WHEN promo_type='BOGOF' then (0.5*base_price)
      END  as price_after_promo
	  from fact_events$ f join dim_campaigns c on f.campaign_id=c.campaign_id
),
cte2 as
(
 select
   f.*,
      f.[quantity_sold(before_promo)]*f.base_price as total_revenue_before_promo,
      f.[quantity_sold(after_promo)]*cte1.price_after_promo as total_revenue_after_promo
     from fact_events$ f
       join cte1 on f.product_code=cte1.product_code
)select 
    top 5 p.product_name,p.category,
	sum(cte2.total_revenue_after_promo)-sum(cte2.total_revenue_before_promo) as IR,
     round((sum(cte2.total_revenue_after_promo)-sum(cte2.total_revenue_before_promo))/sum (cte2.total_revenue_before_promo)*100,2) as IR_per
from cte2
 right join dim_products p
on cte2.product_code=p.product_code
group by p.product_name,p.category
order by IR_per desc;

-----to display the isu% for each category  with rank order in diwali campaign.
----select * from dim_campaigns;
with cte as 
(
 select  
     p.category,
	 round((sum(f.[quantity_sold(after_promo)])- sum(f.[quantity_sold(before_promo)]))/sum(f.[quantity_sold(before_promo)])*100,2) as isu_per 
	 
 from fact_events$ f 
 join dim_products p on p.product_code=f.product_code
 where f.campaign_id='CAMP_DIW_01'
  group by p.category
 )
   select 
    *,
    DENSE_RANK() over(order by isu_per desc) as isu_rank
  from cte
   
---- to display the campaign_name and total revenue before and after promo 
 with cte1 as
(
select
     *,
CASE
      WHEN promo_type='50% OFF' then (0.5*base_price)
      WHEN promo_type='25% OFF' then (base_price*(1-0.25))
      WHEN promo_type='33% OFF' then base_price*(1-0.33)
      WHEN promo_type='500 Cashback' then (base_price-500)
      WHEN promo_type='BOGOF' then (0.5*base_price)
      END  as price_after_promo
	  from fact_events$ 
) ,
cte2 as
(
 select
      f.*,
      f.[quantity_sold(before_promo)]*f.base_price as total_revenue_before_promo,
      f.[quantity_sold(after_promo)]*cte1.price_after_promo as total_revenue_after_promo
      from fact_events$ f
      right join cte1  on f.product_code= cte1.product_code
)
select
c.campaign_name,
concat(round(sum(cte2.total_revenue_before_promo)/1000000,2),'M') as revenue_before_promo ,
concat(round(sum(cte2.total_revenue_after_promo)/1000000,2),'M') as revenue_after_promo from cte2
left join dim_campaigns c on cte2.campaign_id=c.campaign_id
group by c.campaign_name;






