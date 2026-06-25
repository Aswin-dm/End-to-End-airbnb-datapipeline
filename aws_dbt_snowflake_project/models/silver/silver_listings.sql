{{
  config(
    materialized = 'incremental',
    unique_key = 'LISTING_ID',
    on_schema_change = 'append_new_columns'
    )
}}

SELECT 
    LISTING_ID,
    HOST_ID,
    PROPERTY_TYPE,
    ROOM_TYPE,
    CITY,
    COUNTRY,
    ACCOMMODATES,
    BEDROOMS,
    BATHROOMS,
    PRICE_PER_NIGHT,

    {{tag('CAST(PRICE_PER_NIGHT  AS INT)')}} as price_per_night_tag,
    CREATED_AT
    
FROM
    {{ref('bronze_listings')}}