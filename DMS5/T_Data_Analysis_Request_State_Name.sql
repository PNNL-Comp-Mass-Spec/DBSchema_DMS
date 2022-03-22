/****** Object:  Table [dbo].[T_Data_Analysis_Request_State_Name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Data_Analysis_Request_State_Name](
	[State_ID] [tinyint] NOT NULL,
	[State_Name] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Active] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_Data_Analysis_Request_State_Name] PRIMARY KEY CLUSTERED 
(
	[State_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Data_Analysis_Request_State_Name] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Data_Analysis_Request_State_Name] ADD  CONSTRAINT [DF_T_Data_Analysis_Request_State_Name_Active]  DEFAULT ((1)) FOR [Active]
GO
