{{config(materialized = 'ephemeral')}}

WITH LISTINGS AS
(
	SELECT
		LISTING_ID,
		PROPERTY_TYPE,
		ROOM_TYPE,
		CITY,
		COUNTRY,
		PRICE_PER_NIGHT_TAG,
        created_at_lsiting 
	FROM 
		{{ref('obt')}}

)
SELECT * FROM LISTINGS