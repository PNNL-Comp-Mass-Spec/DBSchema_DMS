/****** Object:  Table [dbo].[T_Seq_Local_Symbols_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Seq_Local_Symbols_List](
	[Local_Symbol_ID] [tinyint] IDENTITY(1,1) NOT NULL,
	[Local_Symbol] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Local_Symbol_Comment] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Seq_Local_Symbols_List] PRIMARY KEY CLUSTERED 
(
	[Local_Symbol_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
