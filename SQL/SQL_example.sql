### ЗАДАЧА 1 + проранжировать акции по убыванию количества покупателей
WITH join_buyers AS ( 
	SELECT  MA.Name_MA,
			Clients.Client_ID
	FROM MA
	LEFT JOIN Clients
		ON MA.Ma_ID = Clients.Ma_ID
	
	LEFT JOIN Orders
		ON Clients.Client_ID = Orders.Client_ID
	
	WHERE Orders.Client_ID IS NOT NULL
), 
count_clients AS (
	SELECT t1.Name_MA,
			COUNT(DISTINCT t1.Client_ID) as Buyers
	FROM join_buyers t1
	GROUP BY t1.Name_MA
)
SELECT t1.Name_MA,
		t1.Buyers,
		ROW_NUMBER() OVER(ORDER BY t1.Buyers) as row_num_buyers
FROM count_clients t1;



### ЗАДАЧА 2
WITH shipped_orders AS (
	SELECT *
	FROM table t1
	WHERE t1.Status = 's'
),
accepted_orders AS (
	SELECT *
	FROM table t1
	WHERE t1.Status = 'a'
),
join_orders AS (
	SELECT  t1.id,
			t1.moment as moment_accepted,
			t2.moment as moment_shipped
	FROM accepted_orders t1
	LEFT JOIN shipped_orders t2
		ON t1.id = t2.id
),
diff_date_orders AS (
	SELECT  t1.*,
			datefiff(dd, moment_accepted, moment_shipped) as date_diff
	FROM join_orders t1
)
SELECT MONTH(t1.moment_accepted) as month_accepted,
		t1.id as delayed_orders
FROM diff_date_orders t1
WHERE t1.date_diff > 3;


### ЗАДАЧА 3 
### + посчитать накопительную сумму для акций, отсортированных по алфавиту
WITH sum_ma AS (
	SELECT  MA.Name_MA,
			SUM(Orders.Amnt) as summ_orders
	FROM MA
	LEFT JOIN Orders
		ON MA.Ma_ID = Orders.Ma_ID
	GROUP BY MA.Name_MA
),
filter_ma AS (
	SELECT t1.*
	FROM sum_ma t1
	WHERE t1.summ_orders > (SELECT MAX(T.Amnt) FROM Orders T)
)
SELECT  t1.Name_MA,
		t1.summ_orders,
		SUM(t1.summ_orders) OVER(ORDER BY t1.Name_MA) as summ_cumulative
FROM filter_ma t1;


### Оформить таблицу из задачи 3 в функцию.
### + Натянуть получившиеся суммы на данные о заказах
### + проранжировать данные в разрезе по дате с сортировкой по сумме заказа
### + выбрать первые 5 заказов
DROP FUNCTION IF EXISTS create_table_summ;
CREATE OR REPLACE FUNCTION public.create_table_summ() 
RETURNS TABLE(Odate timestamp, 
			  Amnt float,
			  row_num_price bigint,
			  Ma_ID text,
			  Name_MA text, 
			  summ_orders bigint, 
			  summ_cumulative bigint)  AS $$
BEGIN
	DROP TABLE IF EXISTS table_summ;
	CREATE TABLE table_summ AS
	WITH sum_ma AS (
		SELECT  MA.Ma_ID,
				MA.Name_MA,
				SUM(Orders.Amnt) as summ_orders
		FROM MA
		LEFT JOIN Orders
			ON MA.Ma_ID = Orders.Ma_ID
		GROUP BY MA.Name_MA
	),
	filter_ma AS (
		SELECT t1.*
		FROM sum_ma t1
		WHERE t1.summ_orders > (SELECT MAX(T.Amnt) FROM Orders T)
	),
	filter_cumulative_summ AS (
		SELECT  t1.Ma_ID,
				t1.Name_MA,
				t1.summ_orders,
				SUM(t1.summ_orders) OVER(ORDER BY t1.Name_MA) as summ_cumulative
		FROM filter_ma t1
	),
	filter_row_num AS (
		SELECT t1.Odate,
				t1.Amnt,
				ROW_NUMBER() OVER(PARTITION BY t1.Odate ORDER BY t1.Amnt) as row_num_price,
				t2.Ma_ID,
				t2.Name_MA,
				t2.summ_orders,
				t2.summ_cumulative
		FROM Orders t1 
		LEFT JOIN filter_cumulative_summ t2	
			ON t1.Ma_ID = t2.Ma_ID
	)
	SELECT t1.*
	FROM filter_row_num t1
	WHERE t1.row_num_price BETWEEN 1 AND 5
	;
	
	RETURN QUERY
	SELECT table_summ.*
	FROM table_summ;

END;
$$
LANGUAGE plpgsql;









