/****** Object:  Table [dbo].[T_Archive_Update_State_Name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Archive_Update_State_Name](
	[AUS_stateID] [int] NOT NULL,
	[AUS_name] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [T_Archive_Update_State_Name_PK] PRIMARY KEY CLUSTERED 
(
	[AUS_stateID] ASC
) ON [PRIMARY]
) ON [PRIMARY]

GO
