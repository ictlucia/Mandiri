/* update_method=0 */
SELECT 
  T.TRDNBR 
FROM 
  TRADE T, 
  PORTFOLIOLINK PL, 
  PORTFOLIO OWNER, 
  PORTFOLIO MEMBER 
WHERE 
  T.PRFNBR = PL.MEMBER_PRFNBR 
  AND PL.MEMBER_PRFNBR = MEMBER.PRFNBR 
  AND PL.OWNER_PRFNBR = OWNER.PRFNBR 
  AND DISPLAY_ID(T, 'optkey3_chlnbr') = 'FX' 
  AND DISPLAY_ID(T, 'optkey4_chlnbr') IN (
    'FWD', 'TOD', 'TOM', 'SPOT', 'OPT', 
    'NDF', 'NS', 'SWAP'
  ) 
  AND OWNER.PRFID IN (
    'FXT BMSG - DBU', 'FXT BMSG - ACU'
  ) 
  AND (
    CONVERT('datetime', T.TIME, '%H:%M:%S') >= '18:00:00' 
    OR CONVERT('datetime', T.TIME, '%H:%M:%S') < '08:00:00'
  ) 
  AND T.VALUE_DAY >= TODAY