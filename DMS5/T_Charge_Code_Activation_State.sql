/****** Object:  Table [dbo].[T_Charge_Code_Activation_State] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Charge_Code_Activation_State](
	[Activation_State] [tinyint] NOT NULL,
	[Activation_State_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Charge_Code_Activation_State] PRIMARY KEY CLUSTERED 
(
	[Activation_State] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Charge_Code_Activation_State] TO [DDL_Viewer] AS [dbo]
GO
