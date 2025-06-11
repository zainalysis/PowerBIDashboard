CREATE FUNCTION Report_ForwardingJobProfitAnalysis
(  
	@CurrentCountry as char(2),
	@CompanyPK AS uniqueidentifier,
	@TransactionFrom AS datetime,  --Never call these with null or empty values they are used in a between clause 
	@TransactionTo AS datetime, --If you dont want to filter by them pass in a very small date for From dbo.and a really large one for to 
	@JobType AS varchar(3),
	@OutstandingWIP AS char(1),
	@OutstandingACR AS char(1),
	@ChargeCode AS varchar(4000),
	@ExcludeChargeCode AS varchar(4000),
	@ChargeGroup AS varchar (4000),
	@SalesGroup AS uniqueidentifier,
	@ExpenseGroup AS uniqueidentifier,
	@TransactionBranch AS varchar(4000),
	@TransactionDepartment AS varchar(4000),
	@PostedOnly AS Char(1),
	@RevRecogFrom AS datetime, 
	@RevRecogTo AS datetime,
	@ShipmentTransport AS varchar(3),
	@DeclarationTransport AS varchar (3),
	@ShipmentCont AS varchar(3),
	@DeclarationCont AS varchar (3),
	@ISFTransportMode AS varchar(3),
	@ISFShipmentType AS varchar (3),
	@MNGList dbo.TVP_uniqueidentifier readonly,
	@MNGListIsEmpty bit, 
	@Gateway varchar(3)
)  
RETURNS TABLE AS  
RETURN
WITH
CTE_OrgRelatedParty AS
(
	SELECT
		PR_OH_Parent,
		PR_OH_RelatedParty = MIN(PR_OH_RelatedParty)
	FROM
		dbo.OrgRelatedParty
	WHERE
		PR_PartyType = 'ARS'
		AND PR_FreightDirection = 'AR'
		AND PR_GC = @CompanyPK
		AND PR_Location = ''
	GROUP BY
		PR_OH_Parent
)
,
CTE_MainQuery AS
(  
	SELECT
		MAX(ABS(WIPAmount)) OVER (PARTITION BY AL_JH) as M_WIP,
		MAX(ABS(ACRAmount)) OVER (PARTITION BY AL_JH) as M_ACR,
		JH_PK,
		JH_OA_AgentCollectAddr,
		JH_OA_LocalChargesAddr,
		JH_ParentID,      
		JH_JobNum,
		JH_JobLocalReference,
		JH_Status,  
		JH_SystemCreateTimeUtc, 
		JH_A_JCL,
		JH_GB, 
		JH_GE, 
		JH_GS_NKRepOps,
		JH_GS_NKRepSales,
		JH_ProfitLossReasonCode,
		AL_JH,
		AL_PK,    
		AL_AC,    
		AL_GE,     
		AL_GB,    
		AL_AH,  
		AL_OH,  
		AL_PostDate,  
		Al_ReverseDate,    
		AL_LineType,
		AL_Desc,
		AL_RevRecognitionType,
		CCB,
		CCBOrgName,
		CAG,
		CAGOrgName,
		MNGName,
		AL_LineAmount,    
		WIPAmount,    
		CSTAmount,    
		ACRAmount,    
		REVAmount,  
		AL_RevenueRecognitionDate,
		AL_LinesExistForCriteria,
		AC_Code,
		AC_Desc,
		AC_ChargeGroup, 
		AH_TransactionNum, 
		AH_OH_Code, 
		AH_OH_FullName, 
	 OverseasAgent.OH_Code AS JH_OverseasAgentCode, 
	 OverseasAgent.OH_PK AS JH_OH_OverseasAgentPK,
	 OrgheaderJH_OA_LocalCharges.OH_PK as JH_LocalClientPK,
	 OrgheaderJH_OA_LocalCharges.OH_Code as JH_LocalClientCode,
	 OrgheaderJH_OA_LocalCharges.OH_FullName as JH_LocalClientFullName,
	 GLBBranchJH.GB_Code as JH_GB_Code, 
	 GLBBranchJH.GB_AccountingGroupCode as JobBranchManagementCode, 
	 GLBDepartmentJH.GE_Code as JH_GE_Code, 
	 GLBBranchAL.GB_Code as AL_GB_Code, 
	 GLBDepartmentAL.GE_Code as AL_GE_Code,
	 Operator.GS_PK as OperatorPK,
	 Sales.GS_PK as SalesPK, 
	 Profit_Shipment.JH_GS_NKRepOps as JH_GS_OpsRep_Code,
	 Profit_Shipment.JH_GS_NKRepSales as JH_GS_SalesRep_Code,
	 SalesGroup.AR_Code AS AC_AR_SalesGroupCode,
	 ExpenseGroup.AR_Code AS AC_AR_ExpenseGroupCode,
	 'SHP' AS OpJobType,
	 JS_SystemCreateTimeUtc AS SystemCreateTime,
	 JS_PackingMode AS OpMode,
	 JS_TransportMode AS TransportMode,
	 JS_RL_NKOrigin AS NKOrigin,
	 JS_E_DEP AS OriginETD,
	 JS_RL_NKDestination AS NKDestination,
	 JS_E_ARV AS DestinationETA,
	 JS_HouseBill AS HouseBillNumber,
	 JS_HouseBillOfLadingType AS HouseBillType,
	 JK_UniqueConsignRef,
	 JK_TransportMode,
	 JK_ConsolMode,
	 JK_RL_NKLoadPort AS LoadPort,
	 JW_ETD AS LoadPortETD,
	 JK_RL_NKDischargePort AS DischargePort,
	 JW_ETA AS DischargePortETA,
	 JK_AgentType,
	 SendingAgent.OH_PK AS SendingForwarderPK,
	 SendingAgent.OH_Code AS SendingForwarderCode,
	 ReceivingAgent.OH_PK AS ReceivingForwarderPK,
	 ReceivingAgent.OH_Code AS ReceivingForwarderCode,
	 Carrier.OH_PK AS ShippingLinePK,
	 Carrier.OH_Code AS ShippingLineCode,
	 Creditor.OH_PK AS CreditorPK,
	 Creditor.OH_Code AS CreditorCode,
	 Consignee.Code AS ConsigneeImporterCode,
	 Consignee.FullName AS ConsigneeImporterFullName,
	 Consignor.Code AS ConsignorShipperSuplierCode,
	 Consignor.FullName AS ConsignorShipperSuplierFullName,
	 IsNull(JobLocalClientARSettlementGroup.OH_Code, OrgheaderJH_OA_LocalCharges.OH_Code) AS JobLocalClientARSettlementGroupCode,
	 IsNull(JobLocalClientARSettlementGroup.OH_FullName, OrgheaderJH_OA_LocalCharges.OH_FullName) AS JobLocalClientARSettlementGroupFullName,
	 IsNull(JobOverseaAgentARSettlementGroup.OH_Code, OverseasAgent.OH_Code) AS JobOverseasAgentARSettlementGroupCode,
	 IsNull(JobOverseaAgentARSettlementGroup.OH_FullName, OverseasAgent.OH_FullName) AS JobOverseasAgentARSettlementGroupFullName,
	 JobShipment.JS_ActualWeight AS ActualWeight,
	 JobShipment.JS_UnitOfWeight AS UnitOfWeight,
	 JobShipment.JS_ActualVolume AS ActualVolume,
	 JobShipment.JS_UnitOfVolume AS UnitOfVolume,
	 JobShipment.JS_ActualChargeable AS ActualChargeable,
	 ChargeableUnitDetails.Value AS ChargeableUnit,
	 Containers.TotalTEU AS TEU, 
	 ISNULL(Containers.Count1,0)+ISNULL(Containers.Count2,0)+ISNULL(Containers.Count3,0) AS TwentyFootEquivalentUnit, 
	 ISNULL(Containers.Count4,0)+ISNULL(Containers.Count5,0)+ISNULL(Containers.Count6,0) AS FortyFootEquivalentUnit,	 
	 ConsolsString.UniqueConsignRef AS FW_Consols, 
	 CASE
		WHEN LEFT(JS_RL_NKOrigin, 2) = LEFT(JS_RL_NKDestination, 2) AND LEFT(JS_RL_NKOrigin, 2) = @CurrentCountry THEN 'Domestic'
		WHEN LEFT(JS_RL_NKOrigin, 2) = @CurrentCountry THEN 'Export'
		WHEN LEFT(JS_RL_NKDestination, 2) = @CurrentCountry THEN 'Import'
		ELSE 'Cross Trade'
	END as FW_Direction,
	FirstLastConsolTransport.FirstLoad_Port as FW_ConsolFirstLoad,
	FirstLastConsolTransport.LastDischarge_Port as FW_ConsolLastDischarge,  
	FirstLastConsolTransport.FirstLoad_ETD as FW_ConsolETD,  
	FirstLastConsolTransport.FirstLoad_ATD as FW_ConsolATD,  
	FirstLastConsolTransport.LastDischarge_ETA as FW_ConsolETA,  
	FirstLastConsolTransport.LastDischarge_ATA as FW_ConsolATA,
	FCLShipmentContainers.ContainerCount as FW_FCLContainerCount,  
	FCLShipmentContainers.TotalTEU as FW_FCLContainerTEU,
	TaxExpenseAmount,
	TaxExpenseRealisationDate,
	DebtorOrg,
	CreditorOrg
FROM 
dbo.csfn_AllJobProfitDetailCoreWithCCBAndCAGInfoWithTaxExpense 
		(
@CompanyPK, @TransactionFrom 
			, @TransactionTo, @JobType
			, '', '', @ChargeCode
			, @ExcludeChargeCode, @ChargeGroup
			, @SalesGroup, @ExpenseGroup
			, @TransactionBranch, @TransactionDepartment
			, @PostedOnly, '', ''			
			, @MNGList, @MNGListIsEmpty
		) as Profit_Shipment 
JOIN dbo.JobShipment 
			on 
			Profit_Shipment.JH_ParentID = JS_PK 
			AND JS_IsForwardRegistered = 1
LEFT JOIN dbo.OrgAddress As OrgAddressJH_OA_LocalCharges ON Profit_Shipment.JH_OA_LocalChargesAddr = OrgAddressJH_OA_LocalCharges.OA_PK 
LEFT JOIN dbo.OrgHeader As OrgheaderJH_OA_LocalCharges ON OrgAddressJH_OA_LocalCharges.OA_OH = OrgheaderJH_OA_LocalCharges.OH_PK 
LEFT JOIN CTE_OrgRelatedParty As OrgRelatedPartyLocalClient ON OrgRelatedPartyLocalClient.PR_OH_Parent = OrgheaderJH_OA_LocalCharges.OH_PK
LEFT JOIN dbo.OrgHeader As JobLocalClientARSettlementGroup ON OrgRelatedPartyLocalClient.PR_OH_RelatedParty = JobLocalClientARSettlementGroup.OH_PK 
LEFT JOIN dbo.GlbBranch GlbBranchJH on JH_GB = GlbBranchJH.GB_PK 
LEFT JOIN dbo.GLBDepartment GLBDepartmentJH on JH_GE =  GLBDepartmentJH.GE_PK 
LEFT JOIN dbo.GlbBranch GlbBranchAL on AL_GB = GlbBranchAL.GB_PK 
LEFT JOIN dbo.GLBDepartment GlbDepartmentAL on AL_GE =  GLBDepartmentAL.GE_PK 
LEFT JOIN dbo.OrgAddress As OverseasAgentAddress ON Profit_Shipment.JH_OA_AgentCollectAddr = OverseasAgentAddress.OA_PK 
LEFT JOIN dbo.OrgHeader As OverseasAgent ON OverseasAgentAddress.OA_OH = OverseasAgent.OH_PK 
LEFT JOIN CTE_OrgRelatedParty As OrgRelatedPartyOverseaAgent ON OrgRelatedPartyOverseaAgent.PR_OH_Parent = OverseasAgent.OH_PK 
LEFT JOIN dbo.OrgHeader As JobOverseaAgentARSettlementGroup ON OrgRelatedPartyOverseaAgent.PR_OH_RelatedParty = JobOverseaAgentARSettlementGroup.OH_PK 
LEFT JOIN dbo.AccChargeCode on AL_AC = AC_PK 
LEFT JOIN dbo.AccGroups As SalesGroup ON AC_AR_SalesGroup = SalesGroup.AR_PK 
LEFT JOIN dbo.AccGroups As ExpenseGroup ON AC_AR_ExpenseGroup = ExpenseGroup.AR_PK 
LEFT JOIN dbo.csfn_ShipmentMainConsol(@CurrentCountry) AS MainConsol ON MainConsol.JS_PK = JobShipment.JS_PK 
LEFT JOIN dbo.JobConsol ON MainConsol.JK_PK = JobConsol.JK_PK 
LEFT JOIN dbo.csfn_MainConsolTransport(@CurrentCountry) ON JW_JK = JobConsol.JK_PK 
LEFT JOIN dbo.OrgAddress as ReceivingAgentAddr on ReceivingAgentAddr.OA_PK = JK_OA_ReceivingForwarderAddress 
LEFT JOIN dbo.OrgHeader  As ReceivingAgent On ReceivingAgent.OH_PK = ReceivingAgentAddr.OA_OH 
LEFT JOIN dbo.OrgAddress as SendingAgentAddr on SendingAgentAddr.OA_PK = JK_OA_SendingForwarderAddress 
LEFT JOIN dbo.OrgHeader  As SendingAgent On SendingAgent.OH_PK = SendingAgentAddr.OA_OH 
LEFT JOIN dbo.OrgAddress as CarrierAddr on CarrierAddr.OA_PK = JK_OA_ShippingLineAddress 
LEFT JOIN dbo.OrgHeader  As Carrier On Carrier.OH_PK = CarrierAddr.OA_OH 
LEFT JOIN dbo.OrgAddress As CreditorAddr on CreditorAddr.OA_PK = JK_OA_CreditorAddress 
LEFT JOIN dbo.OrgHeader As Creditor on  Creditor.OH_PK = CreditorAddr.OA_OH 
LEFT JOIN dbo.GlbStaff Operator ON Operator.GS_Code = Profit_Shipment.JH_GS_NKRepOps 
LEFT JOIN dbo.GlbStaff Sales ON Sales.GS_Code = Profit_Shipment.JH_GS_NKRepSales 
LEFT JOIN 
( 
			SELECT E2_ParentID
				, CASE E2_AddressOverride WHEN 1 THEN '' ELSE OH_Code END AS Code
				, CASE E2_AddressOverride WHEN 1 THEN E2_CompanyName ELSE OH_FullName END AS FullName
FROM dbo.JobDocAddress 
INNER JOIN dbo.OrgAddress ON E2_OA_Address = OA_PK 
INNER JOIN dbo.OrgHeader ON OA_OH = OH_PK 
			WHERE E2_AddressType = 'CED' AND E2_ParentTableCode = 'JS'
		) Consignee ON Consignee.E2_ParentID = JobShipment.JS_PK
LEFT JOIN 
( 
			SELECT E2_ParentID
				, CASE E2_AddressOverride WHEN 1 THEN '' ELSE OH_Code END AS Code
				, CASE E2_AddressOverride WHEN 1 THEN E2_CompanyName ELSE OH_FullName END AS FullName
FROM dbo.JobDocAddress 
INNER JOIN dbo.OrgAddress ON E2_OA_Address = OA_PK 
INNER JOIN dbo.OrgHeader ON OA_OH = OH_PK 
			WHERE E2_AddressType = 'CRD' AND E2_ParentTableCode = 'JS'
		) Consignor ON Consignor.E2_ParentID = JobShipment.JS_PK
LEFT JOIN dbo.FCLShipmentContainers('20F,20H,20R,40F,40H,40R') Containers ON Containers.ShipmentPK = JobShipment.JS_PK 
LEFT JOIN dbo.FCLShipmentContainers('') AS FCLShipmentContainers ON JobShipment.JS_PK = FCLShipmentContainers.ShipmentPK 
LEFT JOIN dbo.ViewFirstLastConsolTransport AS FirstLastConsolTransport ON FirstLastConsolTransport.ParentType = 'CON' AND FirstLastConsolTransport.JK = JobConsol.JK_PK 
CROSS APPLY dbo.getConsolsStringForShipment(JobShipment.JS_PK) AS ConsolsString 
CROSS APPLY dbo.IsUnitMetric(JobShipment.JS_UnitOfWeight, JobShipment.JS_UnitOfVolume) AS IsUnitMetric
CROSS APPLY dbo.GetChargeableUnit(JobShipment.JS_TransportMode, IsUnitMetric.Value) AS ChargeableUnitDetails
	WHERE
		Profit_Shipment.AL_JH IS NOT NULL
		AND (ISNULL(@ShipmentTransport, '') = '' OR @ShipmentTransport = JS_TransportMode)
		AND (@ShipmentCont IS NULL OR @ShipmentCont = JS_PackingMode)
		AND
		(
			ISNULL(@Gateway, '') = ''
			OR (@Gateway = 'ALL')
			OR (@Gateway = 'GTW' AND (JK_SendingForwarderHandlingType <> '' OR JK_ReceivingForwarderHandlingType <> ''))
			OR (@Gateway = 'NGW' AND (JK_SendingForwarderHandlingType = '' AND JK_ReceivingForwarderHandlingType = ''))
			OR (@Gateway = 'GTS' AND JK_SendingForwarderHandlingType <> '')
			OR (@Gateway = 'GTR' AND JK_ReceivingForwarderHandlingType <> '')
			OR (@Gateway = 'GTB' AND (JK_SendingForwarderHandlingType <> '' AND JK_ReceivingForwarderHandlingType <> ''))
		)
	
	UNION ALL

	SELECT    
	MAX(ABS(WIPAmount)) OVER (PARTITION BY AL_JH) as M_WIP,
	MAX(ABS(ACRAmount)) OVER (PARTITION BY AL_JH) as M_ACR,
	JH_PK,
	JH_OA_AgentCollectAddr,
	JH_OA_LocalChargesAddr,
	JH_ParentID,      
	JH_JobNum,
	JH_JobLocalReference,
	JH_Status,  
	JH_SystemCreateTimeUtc, 
	JH_A_JCL,
	JH_GB, 
	JH_GE, 
	JH_GS_NKRepOps,
	JH_GS_NKRepSales,
	JH_ProfitLossReasonCode,
	AL_JH,
	AL_PK,    
	AL_AC,    
	AL_GE,     
	AL_GB,    
	AL_AH,  
	AL_OH,  
	AL_PostDate,  
	Al_ReverseDate,    
	AL_LineType,
	AL_Desc,
	AL_RevRecognitionType,
	CCB,
	CCBOrgName,
	CAG,
	CAGOrgName,
	MNGName,
	AL_LineAmount,    
	WIPAmount,    
	CSTAmount,    
	ACRAmount,    
	REVAmount,  
	AL_RevenueRecognitionDate,
	AL_LinesExistForCriteria,
	AC_Code,
	AC_Desc,
	AC_ChargeGroup, 
	AH_TransactionNum,  
	AH_OH_Code, 
	AH_OH_FullName, 
	 OverseasAgent.OH_Code AS JH_OverseasAgentCode, 
	 OverseasAgent.OH_PK AS JH_OH_OverseasAgentPK,
	 OrgheaderJH_OA_LocalCharges.OH_PK as JH_LocalClientPK,
	 OrgheaderJH_OA_LocalCharges.OH_Code as JH_LocalClientCode,
	 OrgheaderJH_OA_LocalCharges.OH_FullName as JH_LocalClientFullName,
	 GLBBranchJH.GB_Code as JH_GB_Code, 
	 GLBBranchJH.GB_AccountingGroupCode as JobBranchManagementCode, 
	 GLBDepartmentJH.GE_Code as JH_GE_Code, 
	 GLBBranchAL.GB_Code as AL_GB_Code, 
	 GLBDepartmentAL.GE_Code as AL_GE_Code,
	 Operator.GS_PK as OperatorPK,
	 Sales.GS_PK as SalesPK, 
	 Profit_Declaration.JH_GS_NKRepOps as JH_GS_OpsRep_Code,
	 Profit_Declaration.JH_GS_NKRepSales as JH_GS_SalesRep_Code,
	 SalesGroup.AR_Code AS AC_AR_SalesGroupCode,
	 ExpenseGroup.AR_Code AS AC_AR_ExpenseGroupCode,
	 'BRK' AS OpJobType,
	 JE_SystemCreateTimeUtc AS SystemCreateTime,
	 JE_ContainerMode AS OpMode,
	 JE_TransportMode AS TransportMode,
	 JE_RL_NKOrigin AS NKOrigin,
	 JE_DateAtOrigin AS OriginETD,
	 JE_RL_NKFinalDestination AS NKDestination,
	 JE_DateAtFinalDestination AS DestinationETA,
	 JE_HouseBill AS HouseBillNumber,
	 '' AS HouseBillType,
	 '' AS JK_UniqueConsignRef,
	 '' AS JK_TransportMode,
	 '' AS JK_ConsolMode,
	 JE_RL_NKPortOfLoading AS LoadPort,
	 JE_ExportDate AS LoadPortETD,
	 JE_RL_NKPortOfArrival AS DischargePort,
	 JE_DateOfArrival AS DischargePortETA,
	 '' AS JK_AgentType,
	 SendingAgent.OH_PK AS SendingForwarderPK,
	 SendingAgent.OH_Code AS SendingForwarderCode,
	 ReceivingAgent.OH_PK AS ReceivingForwarderPK,
	 ReceivingAgent.OH_Code AS ReceivingForwarderCode,
	 Carrier.OH_PK AS ShippingLinePK,
	 Carrier.OH_Code AS ShippingLineCode,
	 NULL AS CreditorPK,
	 '' AS CreditorCode,
	 OrgHeaderImporter.OH_Code AS ConsigneeImporterCode,
	 OrgHeaderImporter.OH_FullName AS ConsigneeImporterFullName,
	 OrgHeaderSuplier.OH_Code AS ConsignorShipperSuplierCode,
	 OrgHeaderSuplier.OH_FullName AS ConsignorShipperSuplierFullName,
	 IsNull(JobLocalClientARSettlementGroup.OH_Code, OrgheaderJH_OA_LocalCharges.OH_Code) AS JobLocalClientARSettlementGroupCode,
	 IsNull(JobLocalClientARSettlementGroup.OH_FullName, OrgheaderJH_OA_LocalCharges.OH_FullName) AS JobLocalClientARSettlementGroupFullName,
	 IsNull(JobOverseaAgentARSettlementGroup.OH_Code, OverseasAgent.OH_Code) AS JobOverseasAgentARSettlementGroupCode,
	 IsNull(JobOverseaAgentARSettlementGroup.OH_FullName, OverseasAgent.OH_FullName) AS JobOverseasAgentARSettlementGroupFullName,
	JE_TotalWeight AS ActualWeight,
	JE_TotalWeightUnit AS UnitOfWeight,
	JE_TotalVolume AS ActualVolume,
	JE_TotalVolumeUnit AS UnitOfVolume,
	NULL ActualChargeable,
	'' ChargeableUnit,
	NULL TEU,
	Container.TwentyFootEquivalentUnit AS TwentyFootEquivalentUnit,
	NULL FortyFootEquivalentUnit,
	NULL AS FW_Consols, 
	JE_MessageType as FW_Direction,
	NULL as FW_ConsolFirstLoad,
	NULL as FW_ConsolLastDischarge,  
	NULL as FW_ConsolETD,  
	NULL as FW_ConsolATD,  
	NULL as FW_ConsolETA,  
	NULL as FW_ConsolATA,
	FCLDeclarationContainers.DecContCount as FW_FCLContainerCount,  
	FCLDeclarationContainers.TotalTEU as FW_FCLContainerTEU,
	TaxExpenseAmount,
	TaxExpenseRealisationDate,
	DebtorOrg,
	CreditorOrg
FROM 
dbo.csfn_AllJobProfitDetailCoreWithCCBAndCAGInfoWithTaxExpense 
		(
@CompanyPK, @TransactionFrom, @TransactionTo, @JobType, '', '', @ChargeCode, @ExcludeChargeCode, @ChargeGroup, @SalesGroup, @ExpenseGroup, @TransactionBranch, @TransactionDepartment, @PostedOnly, '', '', @MNGList, @MNGListIsEmpty
		) as Profit_Declaration
JOIN dbo.JobDeclaration on Profit_Declaration.JH_ParentID = JE_PK 
LEFT JOIN dbo.OrgAddress As OrgAddressJH_OA_LocalCharges ON Profit_Declaration.JH_OA_LocalChargesAddr = OrgAddressJH_OA_LocalCharges.OA_PK 
LEFT JOIN dbo.OrgHeader As OrgheaderJH_OA_LocalCharges ON OrgAddressJH_OA_LocalCharges.OA_OH = OrgheaderJH_OA_LocalCharges.OH_PK 
LEFT JOIN CTE_OrgRelatedParty As OrgRelatedPartyLocalClient ON OrgRelatedPartyLocalClient.PR_OH_Parent = OrgheaderJH_OA_LocalCharges.OH_PK
LEFT JOIN dbo.OrgHeader As JobLocalClientARSettlementGroup ON OrgRelatedPartyLocalClient.PR_OH_RelatedParty = JobLocalClientARSettlementGroup.OH_PK 
LEFT JOIN dbo.GlbBranch GlbBranchJH on JH_GB = GlbBranchJH.GB_PK 
LEFT JOIN dbo.GLBDepartment GLBDepartmentJH on JH_GE =  GLBDepartmentJH.GE_PK 
LEFT JOIN dbo.GlbBranch GlbBranchAL on AL_GB = GlbBranchAL.GB_PK 
LEFT JOIN dbo.GLBDepartment GlbDepartmentAL on AL_GE =  GLBDepartmentAL.GE_PK 
LEFT JOIN dbo.OrgAddress As OverseasAgentAddress ON Profit_Declaration.JH_OA_AgentCollectAddr = OverseasAgentAddress.OA_PK 
LEFT JOIN dbo.OrgHeader As OverseasAgent ON OverseasAgentAddress.OA_OH = OverseasAgent.OH_PK 
LEFT JOIN CTE_OrgRelatedParty As OrgRelatedPartyOverseaAgent ON OrgRelatedPartyOverseaAgent.PR_OH_Parent = OverseasAgent.OH_PK 
LEFT JOIN dbo.OrgHeader As JobOverseaAgentARSettlementGroup ON OrgRelatedPartyOverseaAgent.PR_OH_RelatedParty = JobOverseaAgentARSettlementGroup.OH_PK 
LEFT JOIN dbo.AccChargeCode on AL_AC = AC_PK 
LEFT JOIN dbo.AccGroups As SalesGroup ON AC_AR_SalesGroup = SalesGroup.AR_PK 
LEFT JOIN dbo.AccGroups As ExpenseGroup ON AC_AR_ExpenseGroup = ExpenseGroup.AR_PK 
LEFT JOIN dbo.OrgHeader As SendingAgent ON JE_OH_Forwarder = SendingAgent.OH_PK 
LEFT JOIN dbo.OrgHeader As ReceivingAgent ON JE_OH_Forwarder = ReceivingAgent.OH_PK 
LEFT JOIN dbo.OrgHeader As Carrier ON JE_OH_ShippingLine = Carrier.OH_PK 
LEFT JOIN dbo.GlbStaff Operator ON Operator.GS_Code = Profit_Declaration.JH_GS_NKRepOps 
LEFT JOIN dbo.GlbStaff Sales ON Sales.GS_Code = Profit_Declaration.JH_GS_NKRepSales 
LEFT JOIN dbo.OrgHeader OrgHeaderImporter ON OrgHeaderImporter.OH_PK  = JobDeclaration.JE_OH_Importer 
LEFT JOIN dbo.OrgHeader OrgHeaderSuplier ON OrgHeaderSuplier.OH_PK  = JobDeclaration.JE_OH_Supplier 
LEFT JOIN 
( 
			SELECT CO_JE, SUM(ISNULL(ContainerSummaryFunction.Count1,0) + ISNULL(ContainerSummaryFunction.Count2,0) + ISNULL(ContainerSummaryFunction.Count3,0)) TwentyFootEquivalentUnit 
FROM dbo.CusContainer 
INNER JOIN dbo.ContainerSummaryFunction('20F,20H,20R,40F,40H,40R') ON CO_JC = ContainerSummaryFunction.JC_PK 
			GROUP BY CO_JE
		) Container ON JobDeclaration.JE_PK = Container.CO_JE
LEFT JOIN dbo.FCLDeclarationContainers('') AS FCLDeclarationContainers ON JE_PK = FCLDeclarationContainers.DecPK 
	WHERE
		Profit_Declaration.AL_JH IS NOT NULL
		AND (@DeclarationTransport IS NULL OR @DeclarationTransport = JE_TransportMode)
		AND (@DeclarationCont IS NULL OR @DeclarationCont = JE_ContainerMode)
		
	UNION ALL

	SELECT
		MAX(ABS(WIPAmount)) OVER (PARTITION BY AL_JH) as M_WIP,
		MAX(ABS(ACRAmount)) OVER (PARTITION BY AL_JH) as M_ACR,
		JH_PK,
		JH_OA_AgentCollectAddr,
		JH_OA_LocalChargesAddr,
		JH_ParentID,      
		JH_JobNum,
		JH_JobLocalReference,
		JH_Status,  
		JH_SystemCreateTimeUtc, 
		JH_A_JCL,
		JH_GB, 
		JH_GE, 
		JH_GS_NKRepOps,
		JH_GS_NKRepSales,
		JH_ProfitLossReasonCode,
		AL_JH,
		AL_PK,    
		AL_AC,    
		AL_GE,     
		AL_GB,    
		AL_AH,  
		AL_OH,  
		AL_PostDate,  
		Al_ReverseDate,    
		AL_LineType,
		AL_Desc,
		AL_RevRecognitionType,
		CCB,
		CCBOrgName,
		CAG,
		CAGOrgName,
		MNGName,
		AL_LineAmount,    
		WIPAmount,    
		CSTAmount,    
		ACRAmount,    
		REVAmount,  
		AL_RevenueRecognitionDate,
		AL_LinesExistForCriteria,
		AC_Code,
		AC_Desc,
		AC_ChargeGroup, 
		AH_TransactionNum,  
		AH_OH_Code, 
		AH_OH_FullName, 
	 OverseasAgent.OH_Code AS JH_OverseasAgentCode, 
	 OverseasAgent.OH_PK AS JH_OH_OverseasAgentPK,
	 OrgheaderJH_OA_LocalCharges.OH_PK as JH_LocalClientPK,
	 OrgheaderJH_OA_LocalCharges.OH_Code as JH_LocalClientCode,
	 OrgheaderJH_OA_LocalCharges.OH_FullName as JH_LocalClientFullName,
	 GLBBranchJH.GB_Code as JH_GB_Code, 
	 GLBBranchJH.GB_AccountingGroupCode as JobBranchManagementCode, 
	 GLBDepartmentJH.GE_Code as JH_GE_Code,  
	 GLBBranchAL.GB_Code as AL_GB_Code, 
	 GLBDepartmentAL.GE_Code as AL_GE_Code,
	 Operator.GS_PK as OperatorPK,
	 Sales.GS_PK as SalesPK, 
	 Profit_Gateway.JH_GS_NKRepOps as JH_GS_OpsRep_Code,
	 Profit_Gateway.JH_GS_NKRepSales as JH_GS_SalesRep_Code,
	 SalesGroup.AR_Code AS AC_AR_SalesGroupCode,
	 ExpenseGroup.AR_Code AS AC_AR_ExpenseGroupCode,
	 'GW' AS OpJobType,
	 JK_SystemCreateTimeUtc AS SystemCreateTime,
	 JK_ConsolMode AS OpMode,
	 JK_TransportMode AS TransportMode,
	 '' AS NKOrigin,
	 NULL AS OriginETD,
	 '' AS NKDestination,
	 NULL AS DestinationETA,
	 '' AS HouseBillNumber,
	 '' AS HouseBillType,
	 JK_UniqueConsignRef,
	 JK_TransportMode,
	 JK_ConsolMode,
	 JK_RL_NKLoadPort AS LoadPort,
	 JW_ETD AS LoadPortETD,
	 JK_RL_NKDischargePort AS DischargePort,
	 JW_ETA AS DischargePortETA,
	 JK_AgentType,
	 SendingAgent.OH_PK AS SendingForwarderPK,
	 SendingAgent.OH_Code AS SendingForwarderCode,
	 ReceivingAgent.OH_PK AS ReceivingForwarderPK,
	 ReceivingAgent.OH_Code AS ReceivingForwarderCode,
	 Carrier.OH_PK AS ShippingLinePK,
	 Carrier.OH_Code AS ShippingLineCode,
	 Creditor.OH_PK AS CreditorPK,
	 Creditor.OH_Code AS CreditorCode,
	 OrgHeaderConsigneeImporter.OH_Code AS ConsigneeImporterCode,
	 OrgHeaderConsigneeImporter.OH_FullName AS ConsigneeImporterFullName,
	 OrgHeaderConsignorShipperSuplier.OH_Code AS ConsignorShipperSuplierCode,
	 OrgHeaderConsignorShipperSuplier.OH_FullName AS ConsignorShipperSuplierFullName,
	 IsNull(JobLocalClientARSettlementGroup.OH_Code, OrgheaderJH_OA_LocalCharges.OH_Code) AS JobLocalClientARSettlementGroupCode,
	 IsNull(JobLocalClientARSettlementGroup.OH_FullName, OrgheaderJH_OA_LocalCharges.OH_FullName) AS JobLocalClientARSettlementGroupFullName,
	 IsNull(JobOverseaAgentARSettlementGroup.OH_Code, OverseasAgent.OH_Code) AS JobOverseasAgentARSettlementGroupCode,
	 IsNull(JobOverseaAgentARSettlementGroup.OH_FullName, OverseasAgent.OH_FullName) AS JobOverseasAgentARSettlementGroupFullName,
	 JobConsol.JK_TotalShipmentActWeightCheck AS ActualWeight,
	 JobConsol.JK_TotalShipmentActOtherUnit AS UnitOfWeight,
	 JobConsol.JK_TotalShipmentActVolumeCheck AS ActualVolume,
	 JobConsol.JK_TotalShipmentChargeableUnit AS UnitOfVolume,
	 JobConsol.JK_TotalShipmentChargableCheck AS ActualChargeable,
	 JobConsol.JK_TotalShipmentChargeableUnit AS ChargeableUnit,
	 ConsolContainer.TEU TEU,
	 ConsolContainer.TwentyFootEquivalentUnit TwentyFootEquivalentUnit,
	 ConsolContainer.FourtyFootEquivalentUnit FortyFootEquivalentUnit,
	 JobConsol.JK_UniqueConsignRef AS FW_Consols, 
	 CASE
		WHEN LEFT(JK_RL_NKLoadPort, 2) = LEFT(JK_RL_NKDischargePort, 2) AND LEFT(JK_RL_NKLoadPort, 2) = @CurrentCountry THEN 'Domestic'
		WHEN LEFT(JK_RL_NKLoadPort, 2) = @CurrentCountry THEN 'Export'
		WHEN LEFT(JK_RL_NKDischargePort, 2) = @CurrentCountry THEN 'Import'
		ELSE 'Cross Trade'
	 END as FW_Direction,
	 FirstLastConsolTransport.FirstLoad_Port as FW_ConsolFirstLoad,
	 FirstLastConsolTransport.LastDischarge_Port as FW_ConsolLastDischarge,  
	 FirstLastConsolTransport.FirstLoad_ETD as FW_ConsolETD,  
	 FirstLastConsolTransport.FirstLoad_ATD as FW_ConsolATD,  
	 FirstLastConsolTransport.LastDischarge_ETA as FW_ConsolETA,  
	 FirstLastConsolTransport.LastDischarge_ATA as FW_ConsolATA,
	 FCLConsolContainers.ContainerCount as FW_FCLContainerCount,  
	 FCLConsolContainers.TotalTEU as FW_FCLContainerTEU,
	TaxExpenseAmount,
	TaxExpenseRealisationDate,
	DebtorOrg,
	CreditorOrg
FROM 
dbo.csfn_AllJobProfitDetailCoreWithCCBAndCAGInfoWithTaxExpense 
( @CompanyPK, @TransactionFrom, @TransactionTo, @JobType, '', '', @ChargeCode, @ExcludeChargeCode, @ChargeGroup, @SalesGroup, @ExpenseGroup, @TransactionBranch, @TransactionDepartment, @PostedOnly, '', '', @MNGList, @MNGListIsEmpty  
		) as Profit_Gateway
JOIN dbo.JobConsol on Profit_Gateway.JH_ParentID = JK_PK 
AND
(
	(ISNULL(@Gateway, '') IN ('ALL', 'GTW', '') AND (JK_SendingForwarderHandlingType <> '' OR JK_ReceivingForwarderHandlingType <> ''))
	OR (@Gateway = 'GTS' AND JK_SendingForwarderHandlingType <> '')
	OR (@Gateway = 'GTR' AND JK_ReceivingForwarderHandlingType <> '')
	OR (@Gateway = 'GTB' AND (JK_SendingForwarderHandlingType <> '' AND JK_ReceivingForwarderHandlingType <> ''))
)
LEFT JOIN dbo.OrgAddress As OrgAddressJH_OA_LocalCharges ON Profit_Gateway.JH_OA_LocalChargesAddr = OrgAddressJH_OA_LocalCharges.OA_PK 
LEFT JOIN dbo.OrgHeader As OrgheaderJH_OA_LocalCharges ON OrgAddressJH_OA_LocalCharges.OA_OH = OrgheaderJH_OA_LocalCharges.OH_PK 
LEFT JOIN CTE_OrgRelatedParty As OrgRelatedPartyLocalClient ON OrgRelatedPartyLocalClient.PR_OH_Parent = OrgheaderJH_OA_LocalCharges.OH_PK
LEFT JOIN dbo.OrgHeader As JobLocalClientARSettlementGroup ON OrgRelatedPartyLocalClient.PR_OH_RelatedParty = JobLocalClientARSettlementGroup.OH_PK 
LEFT JOIN dbo.GlbBranch GlbBranchJH on JH_GB = GlbBranchJH.GB_PK 
LEFT JOIN dbo.GLBDepartment GLBDepartmentJH on JH_GE =  GLBDepartmentJH.GE_PK 
LEFT JOIN dbo.GlbBranch GlbBranchAL on AL_GB = GlbBranchAL.GB_PK 
LEFT JOIN dbo.GLBDepartment GlbDepartmentAL on AL_GE =  GLBDepartmentAL.GE_PK 
LEFT JOIN dbo.OrgAddress As OverseasAgentAddress ON Profit_Gateway.JH_OA_AgentCollectAddr = OverseasAgentAddress.OA_PK 
LEFT JOIN dbo.OrgHeader As OverseasAgent ON OverseasAgentAddress.OA_OH = OverseasAgent.OH_PK 
LEFT JOIN CTE_OrgRelatedParty As OrgRelatedPartyOverseaAgent ON OrgRelatedPartyOverseaAgent.PR_OH_Parent = OverseasAgent.OH_PK 
LEFT JOIN dbo.OrgHeader As JobOverseaAgentARSettlementGroup ON OrgRelatedPartyOverseaAgent.PR_OH_RelatedParty = JobOverseaAgentARSettlementGroup.OH_PK 
LEFT JOIN dbo.AccChargeCode on AL_AC = AC_PK 
LEFT JOIN dbo.AccGroups As SalesGroup ON AC_AR_SalesGroup = SalesGroup.AR_PK 
LEFT JOIN dbo.AccGroups As ExpenseGroup ON AC_AR_ExpenseGroup = ExpenseGroup.AR_PK 
LEFT JOIN dbo.csfn_MainConsolTransport(@CurrentCountry) ON JW_JK = JK_PK 
LEFT JOIN dbo.OrgAddress as ReceivingAgentAddr on ReceivingAgentAddr.OA_PK = JK_OA_ReceivingForwarderAddress 
LEFT JOIN dbo.OrgHeader  As ReceivingAgent On ReceivingAgent.OH_PK = ReceivingAgentAddr.OA_OH 
LEFT JOIN dbo.OrgAddress as SendingAgentAddr on SendingAgentAddr.OA_PK = JK_OA_SendingForwarderAddress 
LEFT JOIN dbo.OrgHeader  As SendingAgent On SendingAgent.OH_PK = SendingAgentAddr.OA_OH 
LEFT JOIN dbo.OrgAddress as CarrierAddr on CarrierAddr.OA_PK = JK_OA_ShippingLineAddress 
LEFT JOIN dbo.OrgHeader  As Carrier On Carrier.OH_PK = CarrierAddr.OA_OH 
LEFT JOIN dbo.OrgAddress As CreditorAddr on CreditorAddr.OA_PK = JK_OA_CreditorAddress 
LEFT JOIN dbo.OrgHeader As Creditor on  Creditor.OH_PK = CreditorAddr.OA_OH 
LEFT JOIN dbo.GlbStaff Operator ON Operator.GS_Code = Profit_Gateway.JH_GS_NKRepOps 
LEFT JOIN dbo.GlbStaff Sales ON Sales.GS_Code = Profit_Gateway.JH_GS_NKRepSales 
LEFT JOIN ( 
					SELECT 
						JC_JK, 
						SUM(ISNULL(ContainerSummaryFunction.Count1,0)+ISNULL(ContainerSummaryFunction.Count2,0)+ISNULL(ContainerSummaryFunction.Count3,0)) TwentyFootEquivalentUnit ,
						SUM(ISNULL(ContainerSummaryFunction.Count4,0)+ISNULL(ContainerSummaryFunction.Count5,0)+ISNULL(ContainerSummaryFunction.Count6,0)) FourtyFootEquivalentUnit,
						SUM(RefContainer.RC_TEU * JobContainer.JC_ContainerCount) AS TEU
FROM dbo.ContainerSummaryFunction('20F,20H,20R,40F,40H,40R') 
LEFT JOIN dbo. JobContainer ON ContainerSummaryFunction.JC_PK = JobContainer.JC_PK 
LEFT JOIN dbo.RefContainer ON JobContainer.JC_RC = RefContainer.RC_PK 
					GROUP BY JC_JK
				  ) ConsolContainer ON ConsolContainer.JC_JK = JobConsol.JK_PK
LEFT JOIN dbo.OrgHeader OrgHeaderConsigneeImporter ON OrgHeaderConsigneeImporter.OH_PK = JK_OA_ReceivingForwarderAddress 
LEFT JOIN dbo.OrgHeader OrgHeaderConsignorShipperSuplier ON OrgHeaderConsignorShipperSuplier.OH_PK = JK_OA_SendingForwarderAddress 
LEFT JOIN ( 
					select JC_JK ConsolPK, SUM(JC_ContainerCount) As ContainerCount, SUM(RefContainer.RC_TEU * JobContainer.JC_ContainerCount) AS TotalTEU
from dbo.JobContainer LEFT JOIN dbo.RefContainer ON JobContainer.JC_RC = RefContainer.RC_PK 
					where JC_JK is not null
					GROUP BY JC_JK
					) FCLConsolContainers ON JobConsol.JK_PK = FCLConsolContainers.ConsolPK
LEFT JOIN dbo.ViewFirstLastConsolTransport AS FirstLastConsolTransport ON FirstLastConsolTransport.ParentType = 'CON' AND FirstLastConsolTransport.JK = JobConsol.JK_PK 
	WHERE
		Profit_Gateway.AL_JH IS NOT NULL
		AND JobConsol.JK_AgentType <> 'CLM'
		AND
		(
			ISNULL(@Gateway, '') = ''
			OR (@Gateway = 'ALL')
			OR (@Gateway = 'GTW' AND (JK_SendingForwarderHandlingType <> '' OR JK_ReceivingForwarderHandlingType <> ''))
			OR (@Gateway = 'NGW' AND (JK_SendingForwarderHandlingType = '' AND JK_ReceivingForwarderHandlingType = ''))
			OR (@Gateway = 'GTS' AND JK_SendingForwarderHandlingType <> '')
			OR (@Gateway = 'GTR' AND JK_ReceivingForwarderHandlingType <> '')
			OR (@Gateway = 'GTB' AND (JK_SendingForwarderHandlingType <> '' AND JK_ReceivingForwarderHandlingType <> ''))
		)
		
	UNION ALL

	SELECT
	MAX(ABS(WIPAmount)) OVER (PARTITION BY AL_JH) as M_WIP,
	MAX(ABS(ACRAmount)) OVER (PARTITION BY AL_JH) as M_ACR,
	JH_PK,
	JH_OA_AgentCollectAddr,
	JH_OA_LocalChargesAddr,
	JH_ParentID,      
	JH_JobNum,
	JH_JobLocalReference,
	JH_Status,  
	JH_SystemCreateTimeUtc, 
	JH_A_JCL,
	JH_GB, 
	JH_GE, 
	JH_GS_NKRepOps,
	JH_GS_NKRepSales,
	JH_ProfitLossReasonCode,
	AL_JH,
	AL_PK,    
	AL_AC,    
	AL_GE,     
	AL_GB,    
	AL_AH,  
	AL_OH,  
	AL_PostDate,  
	Al_ReverseDate,    
	AL_LineType,
	AL_Desc,
	AL_RevRecognitionType,
	CCB,
	CCBOrgName,
	CAG,
	CAGOrgName,
	MNGName,
	AL_LineAmount,    
	WIPAmount,    
	CSTAmount,    
	ACRAmount,    
	REVAmount,  
	AL_RevenueRecognitionDate,
	AL_LinesExistForCriteria,
	 AC_Code,
	 AC_Desc,
	 AC_ChargeGroup, 
	AH_TransactionNum,  
	AH_OH_Code, 
	AH_OH_FullName,  
	 '' AS JH_OverseasAgentCode, 
	 NULL AS JH_OH_OverseasAgentPK,
	 OrgheaderJH_OA_LocalCharges.OH_PK as JH_LocalClientPK,
	 OrgheaderJH_OA_LocalCharges.OH_Code as JH_LocalClientCode,
	 OrgheaderJH_OA_LocalCharges.OH_FullName as JH_LocalClientFullName,
	 GLBBranchJH.GB_Code as JH_GB_Code, 
	 GLBBranchJH.GB_AccountingGroupCode as JobBranchManagementCode, 
	 GLBDepartmentJH.GE_Code as JH_GE_Code, 
	 GLBBranchAL.GB_Code as AL_GB_Code, 
	 GLBDepartmentAL.GE_Code as AL_GE_Code,
	 Operator.GS_PK as OperatorPK,
	 Sales.GS_PK as SalesPK, 
	 Profit_Security.JH_GS_NKRepOps as JH_GS_OpsRep_Code,
	 Profit_Security.JH_GS_NKRepSales as JH_GS_SalesRep_Code,
	 SalesGroup.AR_Code AS AC_AR_SalesGroupCode,
	 ExpenseGroup.AR_Code AS AC_AR_ExpenseGroupCode,
	 'ISF' AS OpJobType,
	 BF_SystemCreateTimeUtc AS SystemCreateTime,
	 BF_ShipmentType AS OpMode,
	 BF_TransportMode AS TransportMode,
	 '' AS NKOrigin,
	 NULL AS OriginETD,
	 '' AS NKDestination,
	 NULL AS DestinationETA,
	 '' AS HouseBillNumber,
	 '' AS HouseBillType,
	 '' AS JK_UniqueConsignRef,
	 '' AS JK_TransportMode,
	 '' AS JK_ConsolMode,
	 '' AS LoadPort,
	 NULL AS LoadPortETD,
	 '' AS DischargePort,
	 '' AS DischargePortETA,
	 '' AS JK_AgentType,
	 NULL AS SendingForwarderPK,
	 '' AS SendingForwarderCode,
	 NULL AS ReceivingForwarderPK,
	 '' AS ReceivingForwarderCode,
	 NULL AS ShippingLinePK,
	 '' AS ShippingLineCode,
	 NULL AS CreditorPK,
	 '' AS CreditorCode,
	 Importer.OH_Code AS ConsigneeImporterCode,
	 Importer.OH_FullName AS ConsigneeImporterFullName,
	 Seller.Code AS ConsignorShipperSuplierCode,
	 Seller.FullName AS ConsignorShipperSuplierFullName,
	 IsNull(JobLocalClientARSettlementGroup.OH_Code, OrgheaderJH_OA_LocalCharges.OH_Code) AS JobLocalClientARSettlementGroupCode,
	 IsNull(JobLocalClientARSettlementGroup.OH_FullName, OrgheaderJH_OA_LocalCharges.OH_FullName) AS JobLocalClientARSettlementGroupFullName,
	 IsNull(JobOverseaAgentARSettlementGroup.OH_Code, OverseasAgent.OH_Code) AS JobOverseasAgentARSettlementGroupCode,
	 IsNull(JobOverseaAgentARSettlementGroup.OH_FullName, OverseasAgent.OH_FullName) AS JobOverseasAgentARSettlementGroupFullName,
	 NULL ActualWeight,
	 '' UnitOfWeight,
	 NULL ActualVolume,
	 '' UnitOfVolume,
	 NULL ActualChargeable,
	 '' ChargeableUnit,
	 NULL TEU,
	 NULL TwentyFootEquivalentUnit,
	 NULL FortyFootEquivalentUnit,
	 NULL AS FW_Consols, 
	 NULL as FW_Direction,
	 NULL as FW_ConsolFirstLoad,
	 NULL as FW_ConsolLastDischarge,  
	 NULL as FW_ConsolETD,  
	 NULL as FW_ConsolATD,  
	 NULL as FW_ConsolETA,  
	 NULL as FW_ConsolATA,
	 NULL as FW_FCLContainerCount,  
	 NULL as FW_FCLContainerTEU,
	TaxExpenseAmount,
	TaxExpenseRealisationDate,
	DebtorOrg,
	CreditorOrg
FROM 
dbo.csfn_AllJobProfitDetailCoreWithCCBAndCAGInfoWithTaxExpense 
( @CompanyPK, @TransactionFrom, @TransactionTo, @JobType, '', '', @ChargeCode, @ExcludeChargeCode, @ChargeGroup, @SalesGroup, @ExpenseGroup, @TransactionBranch, @TransactionDepartment, @PostedOnly, '', '', @MNGList, @MNGListIsEmpty 
	   ) as Profit_Security
JOIN dbo.CusISFHeader on Profit_Security.JH_ParentID = BF_PK 
LEFT JOIN dbo.OrgAddress As OrgAddressJH_OA_LocalCharges ON Profit_Security.JH_OA_LocalChargesAddr = OrgAddressJH_OA_LocalCharges.OA_PK 
LEFT JOIN dbo.OrgHeader As OrgheaderJH_OA_LocalCharges ON OrgAddressJH_OA_LocalCharges.OA_OH = OrgheaderJH_OA_LocalCharges.OH_PK 
LEFT JOIN CTE_OrgRelatedParty As OrgRelatedPartyLocalClient ON OrgRelatedPartyLocalClient.PR_OH_Parent = OrgheaderJH_OA_LocalCharges.OH_PK
LEFT JOIN dbo.OrgHeader As JobLocalClientARSettlementGroup ON OrgRelatedPartyLocalClient.PR_OH_RelatedParty = JobLocalClientARSettlementGroup.OH_PK 
LEFT JOIN dbo.GlbBranch GlbBranchJH on JH_GB = GlbBranchJH.GB_PK 
LEFT JOIN dbo.GLBDepartment GLBDepartmentJH on JH_GE =  GLBDepartmentJH.GE_PK 
LEFT JOIN dbo.GlbBranch GlbBranchAL on AL_GB = GlbBranchAL.GB_PK 
LEFT JOIN dbo.GLBDepartment GlbDepartmentAL on AL_GE =  GLBDepartmentAL.GE_PK 
LEFT JOIN dbo.AccChargeCode on AL_AC = AC_PK 
LEFT JOIN dbo.AccGroups As SalesGroup ON AC_AR_SalesGroup = SalesGroup.AR_PK 
LEFT JOIN dbo.AccGroups As ExpenseGroup ON AC_AR_ExpenseGroup = ExpenseGroup.AR_PK 
LEFT JOIN dbo.GlbStaff Operator ON Operator.GS_Code = Profit_Security.JH_GS_NKRepOps 
LEFT JOIN dbo.GlbStaff Sales ON Sales.GS_Code = Profit_Security.JH_GS_NKRepSales 
LEFT JOIN dbo.OrgHeader Importer ON Importer.OH_PK  = CusISFHeader.BF_OH_Importer 
LEFT JOIN 
( 
			SELECT TOP 1 E2_ParentID
				, CASE E2_AddressOverride WHEN 1 THEN '' ELSE OH_Code END AS Code
				, CASE E2_AddressOverride WHEN 1 THEN E2_CompanyName ELSE OH_FullName END AS FullName
FROM dbo.JobDocAddress 
INNER JOIN dbo.OrgAddress ON E2_OA_Address = OA_PK 
INNER JOIN dbo.OrgHeader ON OA_OH = OH_PK 
			WHERE E2_AddressType = 'SEP' AND E2_ParentTableCode = 'BF'
			ORDER BY E2_AddressSequence ASC	
		) Seller ON Seller.E2_ParentID = CusISFHeader.BF_PK AND CusISFHeader.BF_EntryType IN ('1', '3', '5')
LEFT JOIN dbo.OrgAddress As OverseasAgentAddress   ON Profit_Security.JH_OA_AgentCollectAddr = OverseasAgentAddress.OA_PK 
LEFT JOIN dbo.OrgHeader As OverseasAgent   ON OverseasAgentAddress.OA_OH = OverseasAgent.OH_PK 
LEFT JOIN CTE_OrgRelatedParty As OrgRelatedPartyOverseaAgent ON OrgRelatedPartyOverseaAgent.PR_OH_Parent = OverseasAgent.OH_PK 
LEFT JOIN dbo.OrgHeader As JobOverseaAgentARSettlementGroup ON OrgRelatedPartyOverseaAgent.PR_OH_RelatedParty = JobOverseaAgentARSettlementGroup.OH_PK 
	WHERE
		Profit_Security.AL_JH IS NOT NULL
		AND (@ISFTransportMode IS NULL OR @ISFTransportMode = BF_TransportMode)
		AND (@ISFShipmentType IS NULL OR @ISFShipmentType = BF_ShipmentType)
	)
		
SELECT 
	JH_PK,
	JH_OA_AgentCollectAddr,
	JH_OA_LocalChargesAddr,
	JH_ParentID,      
	JH_JobNum,
	JH_JobLocalReference,
	JH_Status,
	CCB,
	CCBOrgName,
	CAG,
	CAGOrgName,
	MNGName,  
	JH_SystemCreateTimeUtc, 
	JH_A_JCL,
	JH_GB, 
	JH_GE, 
	JH_GS_NKRepOps,
	JH_GS_NKRepSales,
	JH_ProfitLossReasonCode,
	AL_JH,
	AL_PK,    
	AL_AC,    
	AL_GE,     
	AL_GB,    
	AL_AH,  
	AL_OH,  
	AL_PostDate,  
	Al_ReverseDate,    
	AL_LineType,
	AL_Desc,
	AL_RevRecognitionType,
	AL_LineAmount,    
	WIPAmount,    
	CSTAmount,    
	ACRAmount,    
	REVAmount,  
	AL_RevenueRecognitionDate,
	AL_LinesExistForCriteria,
	AC_Code,
	AC_Desc,
	AC_ChargeGroup, 
	AH_TransactionNum, 
	AH_OH_Code, 
	AH_OH_FullName, 
	JH_OverseasAgentCode, 
	JH_OH_OverseasAgentPK,
	JH_LocalClientPK,
	JH_LocalClientCode,
	JH_LocalClientFullName,
	JH_GB_Code, 
	JH_GE_Code, 
	JobBranchManagementCode, 
	AL_GB_Code, 
	AL_GE_Code,
	OperatorPK,
	SalesPK, 
	JH_GS_OpsRep_Code,
	JH_GS_SalesRep_Code,
	AC_AR_SalesGroupCode,
	AC_AR_ExpenseGroupCode,
	OpJobType,
	SystemCreateTime,
	OpMode,
	TransportMode,
	NKOrigin,
	OriginETD,
	NKDestination,
	DestinationETA,
	HouseBillNumber,
	HouseBillType,
	JK_UniqueConsignRef,
	JK_TransportMode,
	JK_ConsolMode,
	LoadPort,
	LoadPortETD,
	DischargePort,
	DischargePortETA,
	JK_AgentType,
	SendingForwarderPK,
	SendingForwarderCode,
	ReceivingForwarderPK,
	ReceivingForwarderCode,
	ShippingLinePK,
	ShippingLineCode,
	CreditorPK,
	CreditorCode,
	ConsigneeImporterCode,
	ConsigneeImporterFullName,
	ConsignorShipperSuplierCode,
	ConsignorShipperSuplierFullName,
	JobLocalClientARSettlementGroupCode,
	JobLocalClientARSettlementGroupFullName,
	JobOverseasAgentARSettlementGroupCode,
	JobOverseasAgentARSettlementGroupFullName,
	ActualWeight,
	UnitOfWeight,
	ActualVolume,
	UnitOfVolume,
	ActualChargeable,
	ChargeableUnit,
	TEU, 
	TwentyFootEquivalentUnit, 
	FortyFootEquivalentUnit,	 
	FW_Consols, 
	FW_Direction,
	FW_ConsolFirstLoad,
	FW_ConsolLastDischarge,  
	FW_ConsolETD,  
	FW_ConsolATD,  
	FW_ConsolETA,  
	FW_ConsolATA,
	FW_FCLContainerCount,  
	FW_FCLContainerTEU,
	TaxExpenseAmount,
	TaxExpenseRealisationDate,
	DebtorOrg,
	CreditorOrg
FROM CTE_MainQuery 
LEFT JOIN 
( 
SELECT DISTINCT JH = D3_JH FROM dbo.JobChargeRevRecognition 
WHERE D3_RecognitionDate >= @RevRecogFrom AND D3_RecognitionDate < @RevRecogTo 
) AS RecognisedJobs ON CTE_MainQuery.JH_PK = RecognisedJobs.JH AND (@RevRecogFrom > '1900-01-01 00:00:00' OR @RevRecogTo < '2079-06-06 23:59:29') 
WHERE
(@RevRecogFrom = '1900-01-01 00:00:00' AND @RevRecogTo = '2079-06-06 23:59:29' OR RecognisedJobs.JH IS NOT NULL) 
AND (@OutstandingWIP = '' OR (@OutstandingWIP = 'Y' AND M_WIP > 0))
AND (@OutstandingACR = '' OR (@OutstandingACR = 'Y' AND M_ACR > 0))