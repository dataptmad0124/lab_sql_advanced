select 
    titles.title_id AS "Title ID",
    titleauthor.au_id AS "Author ID",
    titles.price * sales.qty * titles.royalty / 100 * titleauthor.royaltyper / 100 AS "Sales Royalty",
    titles.title
from publication.titles
join  publication.titleauthor 
on titles.title_id = titleauthor.title_id
join publication.sales 
on titles.title_id = sales.title_id;


select 
    subquery.title_id as "Title ID",
    subquery.au_id as "Author ID",
    SUM(subquery.sales_royalty) as "Aggregated Royalties"
from (
    select
        titles.title_id,
        titleauthor.au_id,
        titles.price * sales.qty * titles.royalty / 100 * titleauthor.royaltyper / 100 AS sales_royalty
    from titles
    join titleauthor on titles.title_id = titleauthor.title_id
    join sales on titles.title_id = sales.title_id
) as subquery
group by 
    subquery.title_id,
    subquery.au_id;
    
    select 
    au_id as "Author ID",
    SUM(advance) + SUM("Aggregated Royalties") as "Total Profits"
from (
    select titleauthor.au_id, titles.advance, SUM(subquery.sales_royalty) as "Aggregated Royalties"
    from (
        select titles.title_id, titleauthor.au_id, titles.price * sales.qty * titles.royalty / 100 * titleauthor.royaltyper / 100 AS sales_royalty
        from titles
        join titleauthor on titles.title_id = titleauthor.title_id
        join sales on titles.title_id = sales.title_id
    ) as subquery
    join titles on subquery.title_id = titles.title_id
    join titleauthor on subquery.title_id = titleauthor.title_id
    group by titleauthor.au_id, titles.advance
) as profits_per_author
group by au_id
order by "Total Profits" desc limit 3;


create temporary table temp_sales_royalties as
select  titles.title_id, titleauthor.au_id, titles.price * sales.qty * titles.royalty / 100 * titleauthor.royaltyper / 100 AS sales_royalty
from titles
join titleauthor on titles.title_id = titleauthor.title_id
join sales on titles.title_id = sales.title_id;
    
create temporary table temp_aggregated_royalties as
select title_id, au_id, SUM(sales_royalty) as aggregated_royalties
from temp_sales_royalties
group by title_id, au_id;
    
select temp_aggregated_royalties.au_id, SUM(advance) + SUM(aggregated_royalties) AS "Total Profits"
from temp_aggregated_royalties
join titles on temp_aggregated_royalties.title_id = titles.title_id
join  titleauthor on temp_aggregated_royalties.title_id = titleauthor.title_id
group by au_id
order by "Total Profits" desc limit 3;
    
drop temporary table if exists temp_sales_royalties;
drop temporary table if exists temp_aggregated_royalties;

create table most_profiting_authors (
    au_id VARCHAR(20),
    profits DECIMAL(20, 2)
);

insert into most_profiting_authors
select au_id as "Author ID", SUM(advance) + SUM(aggregated_royalties) as "Profits"
from (
    select titleauthor.au_id, titles.advance, SUM(subquery.sales_royalty) as "aggregated_royalties"
    from (select titles.title_id, titleauthor.au_id, titles.price * sales.qty * titles.royalty / 100 * titleauthor.royaltyper / 100 as sales_royalty
        from titles
        join  titleauthor on titles.title_id = titleauthor.title_id
	    join sales on titles.title_id = sales.title_id
    ) as subquery
    join titles on subquery.title_id = titles.title_id
    join titleauthor on subquery.title_id = titleauthor.title_id
	group by titleauthor.au_id, titles.advance
) as profits_per_author
group by au_id;


