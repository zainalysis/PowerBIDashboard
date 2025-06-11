CREATE FUNCTION IsWeightUnitMetric
(
	@WeightUnit varchar(2)
)

RETURNS TABLE
AS
RETURN
	SELECT Value = CASE WHEN @WeightUnit in ('LB', 'OZ', 'LT', 'OT', 'TL', 'TN') THEN 0 ELSE 1 END