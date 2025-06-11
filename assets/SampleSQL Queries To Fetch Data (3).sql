CREATE FUNCTION IsVolumeUnitMetric
(
	@VolumeUnit varchar(2)
)

RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
	SELECT Value = CASE WHEN @VolumeUnit in ('CF', 'CY', 'CI') THEN 0 ELSE 1 END