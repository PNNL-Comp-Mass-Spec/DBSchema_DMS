/****** Object:  View [dbo].[V_Dataset_Create_Queue] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Dataset_Create_Queue]
AS
SELECT TFCQ.entry_id,
       TFCQ.state_id,
       QS.queue_state_name,
	   TFCQ.dataset,
       TFCQ.experiment,
       TFCQ.instrument,
       TFCQ.separation_type,
       TFCQ.lc_cart,
       TFCQ.lc_cart_config,
       TFCQ.lc_column,
       TFCQ.wellplate,
       TFCQ.well,
       TFCQ.dataset_type,
       TFCQ.operator_username,
       TFCQ.ds_creator_username,
       TFCQ.comment,
       TFCQ.interest_rating,
       TFCQ.request,
       TFCQ.work_package,
       TFCQ.eus_usage_type,
       TFCQ.eus_proposal_id,
       TFCQ.eus_users,
       TFCQ.capture_share_name,
       TFCQ.capture_subdirectory,
       TFCQ.command,
       TFCQ.processor,
       TFCQ.created,
       TFCQ.start,
       TFCQ.finish,
       TFCQ.completion_code,
       TFCQ.completion_message
FROM T_Dataset_Create_Queue TFCQ
     INNER JOIN T_Dataset_Create_Queue_State QS
       ON TFCQ.State_ID = QS.Queue_State_ID

GO
