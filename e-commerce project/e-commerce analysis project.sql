use mavenfuzzyfactory;

-- 데이터 살펴보기 
select * from website_sessions;


-- 트래픽별 세션수 분석
SELECT 
    utm_source,
    utm_campaign,
    http_referer,
    COUNT(DISTINCT website_session_id) AS sessions
FROM
    website_sessions
GROUP BY utm_source , utm_campaign , http_referer
ORDER BY sessions DESC;

-- 트래픽 별 주문수 같이 보기
SELECT 
    utm_source,
    utm_campaign,
    http_referer,
    COUNT(DISTINCT w.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders
FROM
    website_sessions w
        LEFT JOIN
    orders o ON o.website_session_id = w.website_session_id
GROUP BY 1 , 2 , 3
ORDER BY 4 DESC;

-- gsearch/bsearch 세션수, 주문수, 전환율 탐색
SELECT 
    w.utm_source,
    w.utm_campaign,
    COUNT(DISTINCT w.website_session_id) AS sessions,
    count(distinct o.order_id) as orders,
    count(distinct o.order_id)/COUNT(DISTINCT w.website_session_id) as session_to_orders_conv_rate
FROM
    website_sessions w
left join orders o on o.website_session_id = w.website_session_id
WHERE 
	w.utm_source in ('gsearch', 'bsearch') and w.utm_campaign = 'nonbrand'
group by 1,2
ORDER BY 5 DESC;

-- gsearch/nonbrand 주간별 세션수 확인하기. (첫주 첫날 기준)
SELECT 
    min(date(created_at)) as week_started_at,
    COUNT(DISTINCT website_session_id) AS sessions 
FROM
    website_sessions
WHERE 
	utm_source = 'gsearch' and utm_campaign = 'nonbrand'
group by year(created_at), week(created_at),utm_source
order by min(date(created_at));

SELECT 
    w.device_type,
    COUNT(DISTINCT w.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) / COUNT(DISTINCT w.website_session_id) AS session_to_orders_conv_rate
FROM
    website_sessions w
        LEFT JOIN
    orders o ON o.website_session_id = w.website_session_id
WHERE
    w.utm_source = 'gsearch'
        AND w.utm_campaign = 'nonbrand'
GROUP BY device_type;

-- 접속 기기별 주간 트래픽 비교하기 
SELECT 
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(CASE
        WHEN device_type = 'desktop' THEN website_session_id
        ELSE NULL
    END) AS dtop_sessions,
    COUNT(CASE
        WHEN device_type = 'mobile' THEN website_session_id
        ELSE NULL
    END) AS mobile_sessions
FROM
    website_sessions
WHERE
    utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
GROUP BY YEAR(created_at) , WEEK(created_at)
ORDER BY MIN(DATE(created_at));

-- 접속 기기별 gsearch 와 bsearch 더 자세히 비교하기

- week start date, desktop g and bsearch, %of bsearch, mobile of g and b search sessions, % of bsearch

SELECT 
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(CASE
        WHEN
            utm_source = 'gsearch'
                AND device_type = 'desktop'
        THEN
            website_session_id
        ELSE NULL
    END) AS dt_gsearch_sessions,
    COUNT(CASE
        WHEN
            utm_source = 'bsearch'
                AND device_type = 'desktop'
        THEN
            website_session_id
        ELSE NULL
    END) AS dt_bsearch_sessions,
    COUNT(CASE
        WHEN
            utm_source = 'bsearch'
                AND device_type = 'desktop'
        THEN
            website_session_id
        ELSE NULL
    END) / COUNT(CASE
        WHEN
            utm_source = 'gsearch'
                AND device_type = 'desktop'
        THEN
            website_session_id
        ELSE NULL
    END) AS dt_b_percentage_of_g,
    COUNT(CASE
        WHEN
            utm_source = 'gsearch'
                AND device_type = 'mobile'
        THEN
            website_session_id
        ELSE NULL
    END) AS mb_gsearch_sessions,
    COUNT(CASE
        WHEN
            utm_source = 'bsearch'
                AND device_type = 'mobile'
        THEN
            website_session_id
        ELSE NULL
    END) AS mb_bsearch_sessions,
    COUNT(CASE
        WHEN
            utm_source = 'bsearch'
                AND device_type = 'mobile'
        THEN
            website_session_id
        ELSE NULL
    END) / COUNT(CASE
        WHEN
            utm_source = 'gsearch'
                AND device_type = 'mobile'
        THEN
            website_session_id
        ELSE NULL
    END) AS mb_b_percentage_of_g
FROM
    website_sessions
WHERE created_at >= '2012-08-19' and
    utm_campaign = 'nonbrand'
GROUP BY YEARWEEK(created_at);

-- 트래픽 별 Nonbrand 세션 수 대비 월별(weekly) 변화량 (시작)

CREATE TABLE channel_group SELECT website_session_id,
    created_at,
    CASE
        WHEN
            utm_source IS NULL
                AND http_referer IN ('https://www.gsearch.com' , 'https://www.bsearch.com')
        THEN
            'organic search'
        WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
        WHEN utm_campaign = 'brand' THEN 'paid_brand'
        WHEN
            utm_source IS NULL
                AND http_referer IS NULL
        THEN
            'direct type in'
    END AS channel_group FROM
    website_sessions;

select year(created_at) as yr, 
month(created_at) as mo,
count(case when channel_group='paid_nonbrand' then website_session_id else null end) as nonbrand,
count(case when channel_group='paid_brand' then website_session_id else null end) as brand,
count(case when channel_group='paid_brand' then website_session_id else null end) /
count(case when channel_group='paid_nonbrand' then website_session_id else null end) as brand_pct_of_nonbrand,
count(case when channel_group='direct type in' then website_session_id else null end) as direct,
count(case when channel_group='direct type in' then website_session_id else null end)/ 
count(case when channel_group='paid_nonbrand' then website_session_id else null end) as direct_pct_of_nonbrand, 
count(case when channel_group='organic search' then website_session_id else null end) as organic,
count(case when channel_group='organic search' then website_session_id else null end)/
count(case when channel_group='paid_nonbrand' then website_session_id else null end) as organic_pct_of_nonbrand
from channel_group
group by 1,2;
-- 트래픽 별 Nonbrand 세션 수 대비 월별(weekly) 변화량 (종료)

-- 페이지뷰(pageviews) 테이블 살펴보기 
select * from website_pageviews;

-- 랜딩 페이지 성과 분석 시작!
# 1단계: 각각 페이지별 조회수 확인하기 
select pageview_url, count(website_session_id) as views_count
from website_pageviews
group by pageview_url
order by 2 desc;

# 2단계: 세션 아이디별 최소 페이지뷰 아이디 확인하기
-- create temporary table first_visit_page
select website_session_id, min(website_pageview_id) as min_pv_id from website_pageviews
group by website_session_id;

# 3단계: pagegiew_url 페이지별 방문한 총 조회수 확인하기
select w.pageview_url as landing_page,
count(distinct f.website_session_id) as sessions_hitting_this_page
from first_visit_page f
left join website_pageviews w on f.min_pv_id = w.website_pageview_id
group by landing_page
order by sessions_hitting_this_page desc;

#9
-- 이탈률 (bounce rate) 확인하기
# 1단계
create temporary table first_pageviews
SELECT 
    wp.website_session_id,
    MIN(wp.website_pageview_id) AS min_pageview_id
FROM
    website_pageviews wp
        inner JOIN
    website_sessions ws ON ws.website_session_id = wp.website_session_id
GROUP BY wp.website_session_id;

# 2단계
select * from first_pageviews;
-- bring landing page to each sessions

create temporary table sessions_w_landingpage
SELECT 
    fp.website_session_id,
    wp.pageview_url AS landing_page
FROM
first_pageviews fp
        left JOIN
    website_pageviews wp ON wp.website_pageview_id = fp.min_pageview_id;
# 3단계    
select * from sessions_w_landingpage;
-- create bounced sessions 
create temporary table bounced_sessions
select ld.website_session_id, ld.landing_page, count(wp.website_pageview_id) as count_of_pages_views
from sessions_w_landingpage ld 
left join website_pageviews wp on wp.website_session_id = ld.website_session_id
group by ld.website_session_id, ld.landing_page
having count(wp.website_pageview_id) = 1; 

select * from bounced_sessions;
# 4단계
-- connect sessions and bounced sessions 
SELECT 
    ld.landing_page,
    ld.website_session_id,
    bs.website_session_id AS bounced_website_session_id
FROM
    sessions_w_landingpage ld
        LEFT JOIN
    bounced_sessions bs ON bs.website_session_id = ld.website_session_id
ORDER BY ld.website_session_id;
# 5단계 최종 결과
-- final output
SELECT 
    ld.landing_page,
    COUNT(DISTINCT ld.website_session_id) AS sessions,
    COUNT(DISTINCT bs.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT bs.website_session_id) / COUNT(DISTINCT ld.website_session_id) AS bounce_rate
FROM
    sessions_w_landingpage ld
        LEFT JOIN
    bounced_sessions bs ON bs.website_session_id = ld.website_session_id
GROUP BY ld.landing_page
ORDER BY 4 DESC;

-- 페이지별 전환율 분석 (시작)
drop table if exists sessions_level_to_each_page;
create temporary table sessions_level_to_each_page
select website_session_id, 
max(products_page) as to_products, 
max(product1_page) as to_product1, 
max(cart_page) as to_cart, 
max(shipping_page) as to_shipping,
max(billing_page) as to_billing, 
max(thankyou_page) as to_thankyou
from ( SELECT 
    website_sessions.website_session_id,
    website_pageviews.pageview_url,
    -- website_pageviews.created_at,
    CASE
        WHEN pageview_url = '/products' THEN 1
        ELSE 0
    END AS products_page,
    CASE
        WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1
        ELSE 0
    END AS product1_page,
    CASE
        WHEN pageview_url = '/cart' THEN 1
        ELSE 0
    END AS cart_page,
    CASE
        WHEN pageview_url = '/shipping' THEN 1
        ELSE 0
    END AS shipping_page,
    CASE
        WHEN pageview_url = '/billing' or pageview_url = '/billing-2' THEN 1
        ELSE 0
    END AS billing_page,
    CASE
        WHEN pageview_url = '/thank-you-for-your-order' THEN 1
        ELSE 0
    END AS thankyou_page
FROM
    website_sessions
        LEFT JOIN
    website_pageviews ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE
	website_sessions.utm_source = 'gsearch'
        AND website_sessions.utm_campaign = 'nonbrand'
ORDER BY 1) as pageview_level
group by website_session_id;

drop table if exists count_total_sessions_to_page;
create temporary table count_total_sessions_to_page
select count(distinct website_session_id) as sessions, 
		count(distinct case when to_products=1 then website_session_id else null end) as to_products,
        count(distinct case when to_product1=1 then website_session_id else null end) as to_product1,
        count(distinct case when to_cart=1 then website_session_id else null end) as to_cart,
        count(distinct case when to_shipping=1 then website_session_id else null end) as to_shipping,
        count(distinct case when to_billing=1 then website_session_id else null end) as to_billing,
		count(distinct case when to_thankyou=1 then website_session_id else null end) as to_thankyou
from sessions_level_to_each_page;

SELECT 
    to_products / sessions AS lander_click_rt,
    to_product1 / to_products AS products_click_rt,
    to_cart / to_product1 AS product1_click_rt,
    to_shipping / to_cart AS cart_click_rt,
    to_billing / to_shipping AS shipping_click_rt,
    to_thankyou / to_billing AS billing_click_rt
FROM
    count_total_sessions_to_page;

-- 페이지별 전환율 분석 (종료)

-- billing vs billing-2 페이지 결제 전환율 a/b 테스트 (시작!)
select min(website_pageview_id) as first_pv_id
from website_pageviews 
where pageview_url = '/billing-2';

drop table if exists billing_pages;
create temporary table billing_pages
SELECT 
    website_pageviews.website_session_id,
    website_pageviews.pageview_url as billing_versions_seen,
    orders.order_id
    FROM
    website_pageviews
        LEFT JOIN
    orders ON website_pageviews.website_session_id = orders.website_session_id
WHERE
	website_pageviews.website_pageview_id >= 55350
    and website_pageviews.pageview_url in ('/billing', '/billing-2');
    
SELECT 
    billing_versions_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id) / COUNT(DISTINCT website_session_id) AS billing_to_order_rt
FROM
    billing_pages
GROUP BY billing_versions_seen;

-- billing vs billing-2 페이지 결제 전환율 a/b 테스트 (종료)


-- 고객 행동 데이터 분석하기 

# 반복 횟수별 고객수 확인하기  
-- step 1: Identify the relevent new sessions
-- step 2: user the user_id values from step 1 to find any repeat sessions those users had
-- step 3: analyze the data at the user level (how many session did each users had?)
-- step 4: aggregate the user-level analysis to generate your behavioral analysis 
create temporary table sessions_w_repeats
select new_sessions.user_id,
new_sessions.website_session_id as new_session_id,
website_sessions.website_session_id as repeat_session_id
from
(select user_id, website_session_id from website_sessions
where is_repeat_session = 0) as new_sessions
left join website_sessions
on website_sessions.user_id = new_sessions.user_id
and website_sessions.is_repeat_session = 1
and website_sessions.website_session_id > new_sessions.website_session_id; -- session was later than new session


select repeat_sessions, count(distinct user_id) as users
from (
select user_id, count(distinct new_session_id) as new_sessions,
count(distinct repeat_session_id) as repeat_sessions
from sessions_w_repeats
group by 1
order by 3 desc) as users_level
group by 1;

# 첫 세션 이후 두번째 세션까지 평군, 최소, 최대 소요일 확인
/* minimum, maximum, and average time between the first and second session for
customers who do come back */
-- columns : avg_days_first_to_second / min_days_first_to_second / max_days_first_to_second
drop table sessions_w_repeats2;
create temporary table sessions_w_repeats2
select new_sessions.user_id,
new_sessions.created_at as new_session_date,
new_sessions.website_session_id as new_session_id,
website_sessions.website_session_id as repeat_session_id,
website_sessions.created_at as repeat_date
from
(select user_id, website_session_id, created_at from website_sessions
where is_repeat_session = 0) as new_sessions
left join website_sessions
on website_sessions.user_id = new_sessions.user_id
and website_sessions.is_repeat_session = 1
and website_sessions.website_session_id > new_sessions.website_session_id; -- session was later than new session


create table users_first_to_second
select user_id, datediff(second_session_created_at, new_session_date) as days_frist_to_second
from (SELECT 
    user_id,
	new_session_id,
    new_session_date,
    min(repeat_session_id) AS second_session_id,
    MIN(repeat_date) AS second_session_created_at
FROM
    sessions_w_repeats2
    where repeat_session_id is not null
GROUP BY 1,2,3) as first_second;



select 
avg(days_frist_to_second) as avg_days_first_to_second,
min(days_frist_to_second) as min_days_first_to_second,
max(days_frist_to_second) as max_days_first_to_second
from users_first_to_second;

# 트래픽 별 반복 세션수 확인하기
SELECT 
    CASE
        WHEN
            utm_source IS NULL
                AND http_referer IN ('https://www.gsearch.com' , 'https://www.bsearch.com')
        THEN
            'organic_search'
        WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
        WHEN utm_campaign = 'brand' THEN 'paid_brand'
        WHEN utm_source = 'socialbook' THEN 'paid_social'
        WHEN
            utm_source IS NULL
                AND http_referer IS NULL
        THEN
            'direct_type_in'
    END AS channel_group,
    COUNT(CASE
        WHEN is_repeat_session = 0 THEN website_session_id
        ELSE NULL
    END) AS new_sessions,
    COUNT(CASE
        WHEN is_repeat_session = 1 THEN website_session_id
        ELSE NULL
    END) AS repeat_sessions
FROM
    website_sessions
GROUP BY 1
ORDER BY 3 DESC;