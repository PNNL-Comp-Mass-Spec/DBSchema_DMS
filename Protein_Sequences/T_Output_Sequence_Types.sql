/****** Object:  Table [dbo].[T_Output_Sequence_Types] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Output_Sequence_Types](
	[Output_Sequence_Type_ID] [int] IDENTITY(1,1) NOT NULL,
	[Output_Sequence_Type] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Display] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Description] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Output_Sequence_Types] PRIMARY KEY CLUSTERED 
(
	[Output_Sequence_Type_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
