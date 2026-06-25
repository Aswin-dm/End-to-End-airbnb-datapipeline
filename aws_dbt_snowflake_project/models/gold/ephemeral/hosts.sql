{{ config (materialized = 'ephemeral')}}

WITH HOSTS AS
(
    SELECT
        HOST_ID,
        HOST_NAME,
        HOST_SINCE,
        IS_SUPERHOST,
        PRESPONSE_RATE_QUALITY,
        created_at_host
    FROM 
        {{ref('obt')}}

)
SELECT * FROM HOSTS