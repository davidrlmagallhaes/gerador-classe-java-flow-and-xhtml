-----------------------------------------------------------------------------------------------------------
--Tabela temporaria que será composto os dados para gerar o FLOW
-----------------------------------------------------------------------------------------------------------
IF OBJECT_ID(N'tempdb..#flow', N'U') IS NOT NULL
	DROP TABLE #flow;

CREATE TABLE #flow
(
		flow					TEXT
);
-----------------------------------------------------------------------------------------------------------
--Variaveis
-----------------------------------------------------------------------------------------------------------
DECLARE @entidade		VARCHAR(50)
DECLARE @tabelaNome		VARCHAR(50);
DECLARE @colunaNome		VARCHAR(50);
DECLARE @tipoDado		VARCHAR(50);
DECLARE @requerido		BIT;

DECLARE @modulo			VARCHAR(50)
DECLARE @menu			VARCHAR(50)
DECLARE @schema			VARCHAR(50);
DECLARE @sistema		VARCHAR(50);
DECLARE @projeto		VARCHAR(50);

DECLARE @i				INT;
DECLARE @j				INT;

SET @entidade	=	'programacao'
SET @modulo		=	'caesb'
SET @projeto	=	'anfip'
SET @sistema	=	'smartanfip'
SET @menu		=	'cadastro' 

SET	@schema =	(SELECT DISTINCT TABLE_CATALOG
				 FROM 
						INFORMATION_SCHEMA.COLUMNS  
				 WHERE 
						TABLE_NAME = @entidade
				);

-----------------------------------------------------------------------------------------------------------
--GERANDO FLOW
-----------------------------------------------------------------------------------------------------------
INSERT INTO #flow VALUES ( '<?xml version="1.0" encoding="ISO-8859-1"?>')
INSERT INTO #flow VALUES ( '<flow xmlns="http://www.springframework.org/schema/webflow" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"')
INSERT INTO #flow VALUES ( '	xsi:schemaLocation="http://www.springframework.org/schema/webflow') 
INSERT INTO #flow VALUES ( '		http://www.springframework.org/schema/webflow/spring-webflow-2.0.xsd"')
INSERT INTO #flow VALUES ( '	parent="parent-flow">')
INSERT INTO #flow VALUES ( '')
INSERT INTO #flow VALUES ( '	<var name="bean" class="' + @projeto +'.' + @sistema + '.web.bean.'+ @menu +'.' + @entidade +'Bean" />')
INSERT INTO #flow VALUES ( '')
INSERT INTO #flow VALUES ( '	<on-start>')
INSERT INTO #flow VALUES ( '		<evaluate expression="bean.iniciar()" />')
INSERT INTO #flow VALUES ( '	</on-start>')
INSERT INTO #flow VALUES ( '')
INSERT INTO #flow VALUES ( '	<view-state id="' + LOWER(substring(@entidade, 1,1))  + substring(@entidade, 2,len(@entidade))+ '" />')
INSERT INTO #flow VALUES ( '</flow>')

SELECT * FROM #flow
-----------------------------------------------------------------------------------------------------------
--GERANDO TELA DE PESQUISA
-----------------------------------------------------------------------------------------------------------
IF OBJECT_ID(N'tempdb..#xhtml', N'U') IS NOT NULL
	DROP TABLE #xhtml;

CREATE TABLE #xhtml
(
		xhtml					TEXT
);
-----------------------------------------------------------------------------------------------------------
--Gerando cabeçalho da tela de pesquisa
-----------------------------------------------------------------------------------------------------------		
INSERT INTO #xhtml VALUES ( '<?xml version="1.0" encoding="ISO-8859-1" ?>')
INSERT INTO #xhtml VALUES ( '<ui:composition template="/view/template/padrao.xhtml" xmlns="http://www.w3.org/1999/xhtml"')
INSERT INTO #xhtml VALUES ( '	xmlns:ui="http://java.sun.com/jsf/facelets" xmlns:f="http://java.sun.com/jsf/core" xmlns:h="http://java.sun.com/jsf/html"')
INSERT INTO #xhtml VALUES ( '	xmlns:p="http://primefaces.org/ui" xmlns:caesb="http://caesb/jsf">')
INSERT INTO #xhtml VALUES ( '')
INSERT INTO #xhtml VALUES ( '	<ui:define name="titulo">Pesquisar ' + @entidade +'</ui:define>')
-----------------------------------------------------------------------------------------------------------
--Gerando botão de tela do cadastro
-----------------------------------------------------------------------------------------------------------		
INSERT INTO #xhtml VALUES ( '	<ui:define name="botoes">')
INSERT INTO #xhtml VALUES ( '		<h:form id="botoes">')
INSERT INTO #xhtml VALUES ( '			<p:commandButton value="Cadastrar" actionListener="#{bean.criar}" update=":formEdicao" oncomplete="PF(''dlg'+ UPPER(substring(@entidade, 1,1))  + substring(@entidade, 2,len(@entidade))+''').show()" />')
INSERT INTO #xhtml VALUES ( '		</h:form>')
INSERT INTO #xhtml VALUES ( '	</ui:define>')
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------		
INSERT INTO #xhtml VALUES ( '	<ui:define name="conteudo">')
INSERT INTO #xhtml VALUES ( '')
INSERT INTO #xhtml VALUES ( '		<h:form id="formPesquisa">')
INSERT INTO #xhtml VALUES ( '')
INSERT INTO #xhtml VALUES ( '			<p:focus context="formPesquisa" />')
INSERT INTO #xhtml VALUES ( '			<p:defaultCommand target="pesquisar' + Upper(substring(@entidade, 1,1))  + substring(@entidade, 2,len(@entidade))+ '" />')
INSERT INTO #xhtml VALUES ( '')
INSERT INTO #xhtml VALUES ( '			<p:panel header="Filtro de Pesquisa">')
INSERT INTO #xhtml VALUES ( '')
INSERT INTO #xhtml VALUES ( '				<h:panelGrid columns="3">')
------------------------------------------------------------------------------------------------------------
--CURSOR que gera os dados de pesquisa da tabela principal 
------------------------------------------------------------------------------------------------------------
DECLARE camposPesquisar CURSOR FOR 	
						SELECT	DISTINCT
								st.name
								,CASE ISNULL(pkt.NAME,'') WHEN '' THEN sc.name ELSE (lower(substring( pkt.NAME, 1,1))  + substring( pkt.NAME, 2,len( pkt.NAME))) END
								,CASE ISNULL(pkt.NAME,'') WHEN '' THEN sty.name ELSE REPLACE((Upper(substring(sc.name, 1,1))  + substring(sc.name, 2,len(sc.name))),'_id','') END										
								,sc.is_nullable										
						FROM 
										sys.tables st Inner Join sys.columns sc
													ON st.object_id = sc.object_id
										INNER JOIN sys.systypes sty
													ON sc.system_type_id = sty.xtype
										LEFT JOIN	sys.foreign_key_columns fkc 
													ON fkc.parent_object_id = st.object_id 
													AND fkc.parent_column_id = sc.column_id 
										LEFT JOIN  sys.foreign_keys fk 
													ON fk.object_id = fkc.constraint_object_id
										LEFT JOIN sys.tables pkt
													ON fkc.referenced_object_id = pkt.object_id 
										LEFT JOIN sys.columns pkc
													ON pkt.object_id = pkc.object_id 
													AND fkc.referenced_column_id = pkc.column_id
						WHERE 
										st.name = @entidade										
										AND sc.is_identity = 0
						--ORDER BY 
						--				st.Name ASC, 
						--				sc.column_id ASC	
OPEN camposPesquisar;
FETCH NEXT FROM camposPesquisar INTO @tabelaNome, @colunaNome, @tipoDado, @requerido;
WHILE @@FETCH_STATUS = 0
	BEGIN		
			IF(UPPER(@tipoDado) = UPPER(@colunaNome) )
			BEGIN
			-----------------------------------------------------------------------------------------------------------
			--Gerando selectBooleanCheckbox a partir dcampos booleanos
			-----------------------------------------------------------------------------------------------------------
				INSERT INTO #xhtml VALUES ( '					<caesb:linhaForm label="' + Upper(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+':" '+ 
																'id="filtro' + UPPER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+'"> ')
				INSERT INTO #xhtml VALUES ( '						<p:selectOneMenu value="#{bean.filtro.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+'}" '+ 
																	'> ')
				INSERT INTO #xhtml VALUES ( '							<f:selectItem itemLabel="Selecione ' + Upper(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+'" /> ')
				INSERT INTO #xhtml VALUES ( '							<f:selectItems value="#{bean.registros' + Upper(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome)) + '}" var="item" itemLabel="#{item.descricao}" /> ')
				INSERT INTO #xhtml VALUES ( '						</p:selectOneMenu> ')
				INSERT INTO #xhtml VALUES ( '					</caesb:linhaForm> ')
			END
			ELSE IF (UPPER(@tipoDado) = 'date' OR UPPER(@tipoDado) = 'time' OR UPPER(@tipoDado) = 'timestamp' 
						OR UPPER(@tipoDado) = 'datetime2' OR UPPER(@tipoDado) = 'datetimeoffset' 
						OR UPPER(@tipoDado) = 'smalldatetime' OR UPPER(@tipoDado) = 'datetime')
			BEGIN
			-----------------------------------------------------------------------------------------------------------
			--Gerando calendar a partir de campos de data
			-----------------------------------------------------------------------------------------------------------
				INSERT INTO #xhtml VALUES ( '					<caesb:linhaForm label="' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+':"> ')
				INSERT INTO #xhtml VALUES ( '						<p:calendar locale="pt" value="#{bean.filtro.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+'}" navigator="true" yearRange="1930:2050" ')
				INSERT INTO #xhtml VALUES ( '						id="filtro' + UPPER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+
																	'" showOn="button" required="true" readOnlyInputText="true" ')
				INSERT INTO #xhtml VALUES ( '						pattern="dd/MM/yyyy" showButtonPanel="true" size="9" maxlength="10" > ')
				INSERT INTO #xhtml VALUES ( '						</p:calendar>')
				INSERT INTO #xhtml VALUES ( '					</caesb:linhaForm> ')
			END
			--ELSE IF (UPPER(@tipoDado) = 'real' OR UPPER(@tipoDado) = 'money'  OR UPPER(@tipoDadp) = 'float' 
			--			OR UPPER(@tipoDado) = 'decimal' OR UPPER(@tipoDado) = 'smallmoney')
			--BEGIN
			-----------------------------------------------------------------------------------------------------------
			--Gerando inputNumber a partir de campos de valor monetário
			-----------------------------------------------------------------------------------------------------------									
			--END
			ELSE IF(UPPER(@tipoDado) = 'bit')
			BEGIN
			-----------------------------------------------------------------------------------------------------------
			--Gerando selectOneMenu a partir das tabelas de dados hardcode
			-----------------------------------------------------------------------------------------------------------
				INSERT INTO #xhtml VALUES ( '					<caesb:linhaForm label="' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+':"> ')
				INSERT INTO #xhtml VALUES ( '						<p:selectBooleanCheckbox id="filtro' + UPPER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+'" ' +  
																'value="#{bean.filtro.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+'}" />')
				--INSERT INTO #xhtml VALUES ( '						</p:selectBooleanCheckbox> ')
				INSERT INTO #xhtml VALUES ( '					</caesb:linhaForm> ')				
			END
			ELSE
			BEGIN
			-----------------------------------------------------------------------------------------------------------
			--Gerando inputText a partir de campos 
			-----------------------------------------------------------------------------------------------------------
				INSERT INTO #xhtml VALUES ( '					<caesb:linhaForm label="' + Upper(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+ ':"> ')
				INSERT INTO #xhtml VALUES ( '						<p:inputText id="filtro' + UPPER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+ '" value="#{bean.filtro.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+ '}"  /> ')
				INSERT INTO #xhtml VALUES ( '					</caesb:linhaForm> ')	
			END
																

		FETCH NEXT FROM camposPesquisar INTO @tabelaNome, @colunaNome, @tipoDado, @requerido;
	END
CLOSE camposPesquisar;
DEALLOCATE camposPesquisar;	

INSERT INTO #xhtml VALUES ( '					<p:commandButton id="pesquisar' + Upper(substring(@entidade, 1,1))  + substring(@entidade, 2,len(@entidade))+ '" value="Pesquisar" actionListener="#{bean.pesquisar}" update=":formResultado" />')
INSERT INTO #xhtml VALUES ( '				</h:panelGrid>')
INSERT INTO #xhtml VALUES ( '')
INSERT INTO #xhtml VALUES ( '			</p:panel>')
INSERT INTO #xhtml VALUES ( '')
INSERT INTO #xhtml VALUES ( '		</h:form>')
INSERT INTO #xhtml VALUES ( '')
INSERT INTO #xhtml VALUES ( '		<h:form id="formResultado">')
INSERT INTO #xhtml VALUES ( '')
INSERT INTO #xhtml VALUES ( '			<p:dataTable id="dtResultado" var="' + LOWER(SUBSTRING(@entidade,1,3)) + '" value="#{bean.entidades}" paginator="true" paginatorPosition="bottom"')
INSERT INTO #xhtml VALUES ( '				emptyMessage="Nenhum resultado encontrado" rows="10" rowsPerPageTemplate="10,20,50">')
INSERT INTO #xhtml VALUES ( '				<f:facet name="header">#{bean.entidades.size()}' + @entidade + '(s) adicionado(s)</f:facet>')
INSERT INTO #xhtml VALUES ( '				<p:column style="width:4%">')
INSERT INTO #xhtml VALUES ( '					<p:rowToggler />')
INSERT INTO #xhtml VALUES ( '				</p:column>')
INSERT INTO #xhtml VALUES ( '')
INSERT INTO #xhtml VALUES ( '')
DECLARE camposDataTable CURSOR FOR 	
						SELECT	DISTINCT
								st.name
								,CASE ISNULL(pkt.NAME,'') WHEN '' THEN sc.name ELSE (lower(substring( pkt.NAME, 1,1))  + substring( pkt.NAME, 2,len( pkt.NAME))) END
								,CASE ISNULL(pkt.NAME,'') WHEN '' THEN sty.name ELSE REPLACE((Upper(substring(sc.name, 1,1))  + substring(sc.name, 2,len(sc.name))),'_id','') END										
																		
						FROM 
										sys.tables st Inner Join sys.columns sc
													ON st.object_id = sc.object_id
										INNER JOIN sys.systypes sty
													ON sc.system_type_id = sty.xtype
										LEFT JOIN	sys.foreign_key_columns fkc 
													ON fkc.parent_object_id = st.object_id 
													AND fkc.parent_column_id = sc.column_id 
										LEFT JOIN  sys.foreign_keys fk 
													ON fk.object_id = fkc.constraint_object_id
										LEFT JOIN sys.tables pkt
													ON fkc.referenced_object_id = pkt.object_id 
										LEFT JOIN sys.columns pkc
													ON pkt.object_id = pkc.object_id 
													AND fkc.referenced_column_id = pkc.column_id
						WHERE 
										st.name = @entidade										
										AND sc.is_identity = 0
						--ORDER BY 
						--				st.Name ASC, 
						--				sc.column_id ASC	
OPEN camposDataTable;
FETCH NEXT FROM camposDataTable INTO @tabelaNome, @colunaNome, @tipoDado;
WHILE @@FETCH_STATUS = 0
	BEGIN		
			IF(UPPER(@tipoDado) = UPPER(@colunaNome) )
			BEGIN
				INSERT INTO #xhtml VALUES ( '				<p:column headerText="' + Upper(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome)) + '" style="text-align: center" filterBy="#{' + LOWER(SUBSTRING(@entidade,1,3)) + '.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome)) + '.descricao}" filterMatchMode="contains">')
				INSERT INTO #xhtml VALUES ( '					<h:outputText value="#{' + LOWER(SUBSTRING(@entidade,1,3)) + '.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome)) + '.descricao}" />')
				INSERT INTO #xhtml VALUES ( '				</p:column>')
			END
			ELSE IF (UPPER(@tipoDado) = 'date' OR UPPER(@tipoDado) = 'time' OR UPPER(@tipoDado) = 'timestamp' 
						OR UPPER(@tipoDado) = 'datetime2' OR UPPER(@tipoDado) = 'datetimeoffset' 
						OR UPPER(@tipoDado) = 'smalldatetime' OR UPPER(@tipoDado) = 'datetime')
			BEGIN
				INSERT INTO #xhtml VALUES ( '				<p:column headerText="'+ Upper(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome)) + '" width="100" style="text-align: center" filterBy="#{' + LOWER(SUBSTRING(@entidade,1,3)) + '.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome)) + 'Formatada}" filterMatchMode="contains">')
				INSERT INTO #xhtml VALUES ( '					<h:outputText value="#{' + LOWER(SUBSTRING(@entidade,1,3)) + '.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome)) + '}">')
				INSERT INTO #xhtml VALUES ( '						<f:convertDateTime pattern="dd/MM/yyyy" />')
				INSERT INTO #xhtml VALUES ( '					</h:outputText>')
				INSERT INTO #xhtml VALUES ( '				</p:column>')	
			END
			ELSE IF (UPPER(@tipoDado) = 'real' OR UPPER(@tipoDado) = 'money'  OR UPPER(@tipoDado) = 'float' 
						OR UPPER(@tipoDado) = 'decimal' OR UPPER(@tipoDado) = 'smallmoney')
			BEGIN
				INSERT INTO #xhtml VALUES ( '				<p:column headerText="' + Upper(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome)) + ' R$">')
				INSERT INTO #xhtml VALUES ( '					<h:outputText value="#{' + LOWER(SUBSTRING(@entidade,1,3)) + '.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome)) + '}">')
				INSERT INTO #xhtml VALUES ( '						<f:convertNumber pattern="#,##0.00" />')
				INSERT INTO #xhtml VALUES ( '					</h:outputText>')
				INSERT INTO #xhtml VALUES ( '				</p:column>')							
			END
			ELSE IF(UPPER(@tipoDado) = 'bit')
			BEGIN
				INSERT INTO #xhtml VALUES ( '				<p:column headerText="' + Upper(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome)) + '" filterBy="#{' + LOWER(SUBSTRING(@entidade,1,3)) + '.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome)) + '}" filterMatchMode="contains">')
					INSERT INTO #xhtml VALUES ( '					<h:outputText value="#{if(' + LOWER(SUBSTRING(@entidade,1,3)) + '.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome)) + ') : ''SIM'' ? ''NÃO''}" />')
				INSERT INTO #xhtml VALUES ( '				</p:column>')		
			END
			ELSE
			BEGIN
				INSERT INTO #xhtml VALUES ( '				<p:column headerText="' + Upper(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome)) + '" filterBy="#{' + LOWER(SUBSTRING(@entidade,1,3)) + '.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome)) + '}" filterMatchMode="contains">')
				INSERT INTO #xhtml VALUES ( '					<h:outputText value="#{' + LOWER(SUBSTRING(@entidade,1,3)) + '.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome)) + '}" />')
				INSERT INTO #xhtml VALUES ( '				</p:column>')
			END
		FETCH NEXT FROM camposDataTable INTO @tabelaNome, @colunaNome, @tipoDado;
	END
CLOSE camposDataTable;
DEALLOCATE camposDataTable;	
INSERT INTO #xhtml VALUES ( '')
-----------------------------------------------------------------------------------------------------------
--Gerando rowExpansion dos dados de tabelas relacionais
-----------------------------------------------------------------------------------------------------------		
INSERT INTO #xhtml VALUES ( '				<p:rowExpansion >')
------------------------------------------------------------------------------------------------------------
--CURSOR que gera as tabelas relacionais
------------------------------------------------------------------------------------------------------------
SET @tabelaNome = ''
DECLARE hashset CURSOR FOR	SELECT	DISTINCT
									KCU1.TABLE_NAME AS 'FK_Nome_Tabela'
							FROM 
									INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC
									JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU1
											ON KCU1.CONSTRAINT_CATALOG = RC.CONSTRAINT_CATALOG 
											AND KCU1.CONSTRAINT_SCHEMA = RC.CONSTRAINT_SCHEMA
											AND KCU1.CONSTRAINT_NAME = RC.CONSTRAINT_NAME
									JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU2
											ON KCU2.CONSTRAINT_CATALOG = RC.UNIQUE_CONSTRAINT_CATALOG 
											AND KCU2.CONSTRAINT_SCHEMA = RC.UNIQUE_CONSTRAINT_SCHEMA
											AND KCU2.CONSTRAINT_NAME = RC.UNIQUE_CONSTRAINT_NAME
											AND KCU2.ORDINAL_POSITION = KCU1.ORDINAL_POSITION
									JOIN sys.foreign_keys FK 
											ON FK.name = KCU1.CONSTRAINT_NAME
							WHERE 
									KCU2.TABLE_NAME = @entidade
							Order by 
									KCU1.TABLE_NAME
OPEN hashset
FETCH NEXT FROM hashset into @tabelaNome
WHILE @@FETCH_STATUS = 0
	BEGIN	
		INSERT INTO #xhtml VALUES ( '					<h:panelGrid columns="2" >')
		INSERT INTO #xhtml VALUES ( '						<h:panelGrid columns="2" columnClasses="campo,valor">')	
			------------------------------------------------------------------------------------------------------------
			--CURSOR que gera os campos das tabelas relacionais
			------------------------------------------------------------------------------------------------------------
			DECLARE campos CURSOR FOR	SELECT	DISTINCT
												sc.name
												,sty.name
										FROM 
														sys.tables st Inner Join sys.columns sc
																	on st.object_id = sc.object_id
														Inner Join sys.systypes sty
																	on sc.system_type_id = sty.xtype
										WHERE 
														st.name = @tabelaNome						
														AND REPLACE((Upper(substring(sc.name, 1,1))  + substring(sc.name, 2,len(sc.name))),'_id','') <> @entidade
														AND sc.is_identity = 0
										--ORDER BY 
											--			st.Name ASC, 
											--			sc.column_id ASC		
			OPEN campos
			FETCH NEXT FROM campos into @colunaNome,@tipoDado
			WHILE @@FETCH_STATUS = 0
				BEGIN	
				------------------------------------------------------------------------------------------------------------
				--Gerando os campos do rowExpansion das tabelas relacionais
				------------------------------------------------------------------------------------------------------------
					INSERT INTO #xhtml VALUES ( '							<h:outputLabel value="' + Upper(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+':" />')
					INSERT INTO #xhtml VALUES ( '							<h:outputLabel value="#{' + LOWER(SUBSTRING(@entidade,1,3)) + '.registros' + Upper(substring(@tabelaNome, 1,1))  + substring(@tabelaNome, 2,len(@tabelaNome)) + '.' + REPLACE(LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome)),'_id','') + '}"  />')
					INSERT INTO #xhtml VALUES ( '')

				FETCH NEXT FROM campos INTO @colunaNome,@tipoDado;		
			END;
		CLOSE campos;
		DEALLOCATE campos;	

		INSERT INTO #xhtml VALUES ( '						</h:panelGrid>')
		INSERT INTO #xhtml VALUES ( '					</h:panelGrid>')

		FETCH NEXT FROM hashset INTO @tabelaNome;		
	END;
CLOSE hashset;
DEALLOCATE hashset;	
INSERT INTO #xhtml VALUES ( '				</p:rowExpansion>')
------------------------------------------------------------------------------------------------------------
--Gerando botões de excluir e editar
------------------------------------------------------------------------------------------------------------
INSERT INTO #xhtml VALUES ( '				<p:column styleClass="menuBotoes" rendered="#{caesb:hasAccess(''ALT_' + Upper(@entidade) + ',REM_' + Upper(@entidade) + ''') and not empty bean.entidades}">')
INSERT INTO #xhtml VALUES ( '					<caesb:menuButton>')
INSERT INTO #xhtml VALUES ( '						<p:menuitem icon="ui-icon-pencil" value="Alterar" actionListener="#{bean.setEntidade(' + LOWER(SUBSTRING(@entidade,1,3)) + ')}" update=":formPesquisa,:formEdicao"')
INSERT INTO #xhtml VALUES ( '							oncomplete="PF(''dlg'+ UPPER(substring(@entidade, 1,1))  + substring(@entidade, 2,len(@entidade))+''').show()" rendered="#{caesb:hasAccess(''ALT_' + Upper(@entidade) + ''')}" />')
INSERT INTO #xhtml VALUES ( '')
INSERT INTO #xhtml VALUES ( '						<p:menuitem icon="ui-icon-trash" value="Remover" actionListener="#{bean.remover(' + LOWER(SUBSTRING(@entidade,1,3)) + ')}"')
INSERT INTO #xhtml VALUES ( '							onclick="if (!confirm(''Deseja remover ' + @entidade +'?'')) return false" update=":formPesquisa" rendered="#{caesb:hasAccess(''REM_' + Upper(@entidade) + ''')}" />')
INSERT INTO #xhtml VALUES ( '					</caesb:menuButton>')
INSERT INTO #xhtml VALUES ( '				</p:column>')
INSERT INTO #xhtml VALUES ( '			</p:dataTable>')
INSERT INTO #xhtml VALUES ( '		</h:form>')
INSERT INTO #xhtml VALUES ( '	</ui:define>')
INSERT INTO #xhtml VALUES ( '')
------------------------------------------------------------------------------------------------------------
--Gerando include da tela de edição
------------------------------------------------------------------------------------------------------------
INSERT INTO #xhtml VALUES ( '	<ui:define name="rodape">')
INSERT INTO #xhtml VALUES ( '		<ui:include src="' + LOWER(substring(@entidade, 1,1))  + substring(@entidade, 2,len(@entidade))+ 'Edicao.xhtml" />')
INSERT INTO #xhtml VALUES ( '	</ui:define>')
INSERT INTO #xhtml VALUES ( '</ui:composition>')

SELECT * FROM #xhtml
-----------------------------------------------------------------------------------------------------------
--GERANDO TELA DE EDIÇÃO
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
--Tabela temporaria que será composto os dados para gerar xhtmlEdicao
-----------------------------------------------------------------------------------------------------------
IF OBJECT_ID(N'tempdb..#xhtmlEdicao', N'U') IS NOT NULL
	DROP TABLE #xhtmlEdicao;

CREATE TABLE #xhtmlEdicao
(
		xhtmlEdicao					TEXT
);
-----------------------------------------------------------------------------------------------------------
--Cabeçalho do xhtml
-----------------------------------------------------------------------------------------------------------
INSERT INTO #xhtmlEdicao VALUES ('<?xml version="1.0" encoding="ISO-8859-1" ?>')
INSERT INTO #xhtmlEdicao VALUES ('<ui:fragment template="/view/template/padrao.xhtml" xmlns="http://www.w3.org/1999/xhtml"')
INSERT INTO #xhtmlEdicao VALUES ('	xmlns:ui="http://java.sun.com/jsf/facelets" xmlns:f="http://java.sun.com/jsf/core" xmlns:h="http://java.sun.com/jsf/html"')
INSERT INTO #xhtmlEdicao VALUES ('	xmlns:p="http://primefaces.org/ui" xmlns:caesb="http://caesb/jsf">')
INSERT INTO #xhtmlEdicao VALUES ('')
INSERT INTO #xhtmlEdicao VALUES ('	<p:dialog header="Cadastro de ' + @entidade +'" resizable="true" modal="true" position="center" widgetVar="dlg'+ UPPER(substring(@entidade, 1,1))  + substring(@entidade, 2,len(@entidade)) + '"')
INSERT INTO #xhtmlEdicao VALUES ('		width="950">')
INSERT INTO #xhtmlEdicao VALUES ('')
INSERT INTO #xhtmlEdicao VALUES ('		<h:form id="formEdicao">')
INSERT INTO #xhtmlEdicao VALUES ('			<p:hotkey bind="esc" handler="PF''(dlg'+ UPPER(substring(@entidade, 1,1))  + substring(@entidade, 2,len(@entidade)) +''').hide();" />')
INSERT INTO #xhtmlEdicao VALUES ('			<p:focus context="formEdicao" />')
INSERT INTO #xhtmlEdicao VALUES ('')
INSERT INTO #xhtmlEdicao VALUES ( '			<h:panelGrid columns="3" >')
INSERT INTO #xhtmlEdicao VALUES ('')
INSERT INTO #xhtmlEdicao VALUES ( '				<h:panelGroup>')
INSERT INTO #xhtmlEdicao VALUES ( '					<p:panel header="Dados ' + @entidade + '">')
-----------------------------------------------------------------------------------------------------------
--Gerando o panel da tabela principal
-----------------------------------------------------------------------------------------------------------
DECLARE camposEdicao CURSOR FOR 	
						SELECT	
								DISTINCT st.name
								,CASE ISNULL(pkt.NAME,'') WHEN '' THEN sc.name ELSE (lower(substring( pkt.NAME, 1,1))  + substring( pkt.NAME, 2,len( pkt.NAME))) END
								,CASE ISNULL(pkt.NAME,'') WHEN '' THEN sty.name ELSE REPLACE((Upper(substring(sc.name, 1,1))  + substring(sc.name, 2,len(sc.name))),'_id','') END										
																		
						FROM 
										sys.tables st Inner Join sys.columns sc
													ON st.object_id = sc.object_id
										INNER JOIN sys.systypes sty
													ON sc.system_type_id = sty.xtype
										LEFT JOIN	sys.foreign_key_columns fkc 
													ON fkc.parent_object_id = st.object_id 
													AND fkc.parent_column_id = sc.column_id 
										LEFT JOIN  sys.foreign_keys fk 
													ON fk.object_id = fkc.constraint_object_id
										LEFT JOIN sys.tables pkt
													ON fkc.referenced_object_id = pkt.object_id 
										LEFT JOIN sys.columns pkc
													ON pkt.object_id = pkc.object_id 
													AND fkc.referenced_column_id = pkc.column_id
						WHERE 
										st.name = @entidade
										AND sc.is_identity = 0
						--ORDER BY 
						--				st.Name ASC, 
						--				sc.column_id ASC	
OPEN camposEdicao;
FETCH NEXT FROM camposEdicao INTO @tabelaNome, @colunaNome, @tipoDado;
WHILE @@FETCH_STATUS = 0
	BEGIN	
		IF(UPPER(@tipoDado) = UPPER(@colunaNome) )
		BEGIN
		-----------------------------------------------------------------------------------------------------------
		--Gerando selectOneMenu a partir das tabelas de dados hardcode
		-----------------------------------------------------------------------------------------------------------
			INSERT INTO #xhtmlEdicao VALUES ( '						<caesb:linhaForm label="' + Upper(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+':" '+ 
															'id="' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+'"> ')
			INSERT INTO #xhtmlEdicao VALUES ( '							<p:selectOneMenu value="#{bean.entidade.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+'}" converter="#{' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+'Converter}"> ')
			INSERT INTO #xhtmlEdicao VALUES ( '								<f:selectItem itemLabel="Selecione" /> ')
			INSERT INTO #xhtmlEdicao VALUES ( '								<f:selectItems value="#{bean.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome)) + '}" var="' + SUBSTRING(LOWER(@colunaNome),1,3) + '" itemLabel="#{' + SUBSTRING(LOWER(@colunaNome),1,3) + '.descricao}" itemValue="#{' + SUBSTRING(LOWER(@colunaNome),1,3) + '}"/> ')
			INSERT INTO #xhtmlEdicao VALUES ( '							</p:selectOneMenu> ')
			INSERT INTO #xhtmlEdicao VALUES ( '						</caesb:linhaForm> ')
		END
		ELSE IF (UPPER(@tipoDado) = 'date' OR UPPER(@tipoDado) = 'time' OR UPPER(@tipoDado) = 'timestamp' 
					OR UPPER(@tipoDado) = 'datetime2' OR UPPER(@tipoDado) = 'datetimeoffset' 
					OR UPPER(@tipoDado) = 'smalldatetime' OR UPPER(@tipoDado) = 'datetime')
		BEGIN
		-----------------------------------------------------------------------------------------------------------
		--Gerando calendar a partir de campos de data
		-----------------------------------------------------------------------------------------------------------
			INSERT INTO #xhtmlEdicao VALUES ( '						<caesb:linhaForm label="' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+':"> ')
			INSERT INTO #xhtmlEdicao VALUES ( '							<p:calendar locale="pt" value="#{bean.entidade.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+'}" navigator="true" yearRange="1930:2050" ')
			INSERT INTO #xhtmlEdicao VALUES ( '						id="' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+
																'" showOn="button" required="true" readOnlyInputText="true" ')
			INSERT INTO #xhtmlEdicao VALUES ( '						pattern="dd/MM/yyyy" showButtonPanel="true" size="9" maxlength="10" > ')
			INSERT INTO #xhtmlEdicao VALUES ( '							</p:calendar>')
			INSERT INTO #xhtmlEdicao VALUES ( '						</caesb:linhaForm> ')
		END
		--ELSE IF (UPPER(@tipoDado) = 'real' OR UPPER(@tipoDado) = 'money'  OR UPPER(@tipoDadp) = 'float' 
		--			OR UPPER(@tipoDado) = 'decimal' OR UPPER(@tipoDado) = 'smallmoney')
		--BEGIN
		-----------------------------------------------------------------------------------------------------------
		--Gerando inputNumber a partir de campos de valor monetário
		-----------------------------------------------------------------------------------------------------------								
		--END
		ELSE IF(UPPER(@tipoDado) = 'bit')
		BEGIN
		-----------------------------------------------------------------------------------------------------------
		--Gerando selectBooleanCheckbox a partir dcampos booleanos
		-----------------------------------------------------------------------------------------------------------
			INSERT INTO #xhtmlEdicao VALUES ( '						<caesb:linhaForm label="' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+':"> ')
			INSERT INTO #xhtmlEdicao VALUES ( '							<p:selectBooleanCheckbox id="' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+'" ' +  
															'value="#{bean.entidade.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+'}" />')
			--INSERT INTO #xhtml VALUES ( '						</p:selectBooleanCheckbox> ')
			INSERT INTO #xhtmlEdicao VALUES ( '						</caesb:linhaForm> ')				
		END
		ELSE
		BEGIN
		-----------------------------------------------------------------------------------------------------------
		--Gerando inputText a partir de campos 
		-----------------------------------------------------------------------------------------------------------
			INSERT INTO #xhtmlEdicao VALUES ( '						<caesb:linhaForm label="' + Upper(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+ ':"> ')
			INSERT INTO #xhtmlEdicao VALUES ( '							<p:inputText id="' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+ '" value="#{bean.entidade.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+ '}"  /> ')
			INSERT INTO #xhtmlEdicao VALUES ( '						</caesb:linhaForm> ')	
		END														

		FETCH NEXT FROM camposEdicao INTO @tabelaNome, @colunaNome, @tipoDado;
	END
CLOSE camposEdicao;
DEALLOCATE camposEdicao;	
-----------------------------------------------------------------------------------------------------------
--Fechando o panel da tabela principal
-----------------------------------------------------------------------------------------------------------
INSERT INTO #xhtmlEdicao VALUES ( '					</p:panel>')					
-----------------------------------------------------------------------------------------------------------
--CURSOR que seleciona as tabelas relacionadas a principal
-----------------------------------------------------------------------------------------------------------
SET @tabelaNome = ''
SET @i = 1
DECLARE hashset CURSOR FOR	SELECT 
										DISTINCT KCU1.TABLE_NAME AS 'FK_Nome_Tabela'
										,COUNT(*)
							FROM 
									INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC
									JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU1
											ON KCU1.CONSTRAINT_CATALOG = RC.CONSTRAINT_CATALOG 
											AND KCU1.CONSTRAINT_SCHEMA = RC.CONSTRAINT_SCHEMA
											AND KCU1.CONSTRAINT_NAME = RC.CONSTRAINT_NAME
									JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU2
											ON KCU2.CONSTRAINT_CATALOG = RC.UNIQUE_CONSTRAINT_CATALOG 
											AND KCU2.CONSTRAINT_SCHEMA = RC.UNIQUE_CONSTRAINT_SCHEMA
											AND KCU2.CONSTRAINT_NAME = RC.UNIQUE_CONSTRAINT_NAME
											AND KCU2.ORDINAL_POSITION = KCU1.ORDINAL_POSITION
									JOIN sys.foreign_keys FK 
											ON FK.name = KCU1.CONSTRAINT_NAME
							WHERE 
									KCU2.TABLE_NAME = @entidade
							GROUP BY
								KCU1.TABLE_NAME
							
OPEN hashset
FETCH NEXT FROM hashset into @tabelaNome,@j
WHILE @@FETCH_STATUS = 0
BEGIN	
	IF(@i%2 = 0)
	BEGIN
		INSERT INTO #xhtmlEdicao VALUES ( '				<h:panelGroup>')
	END	
	INSERT INTO #xhtmlEdicao VALUES ( '					<p:panel header="Dados ' + @tabelaNome + '">')
	INSERT INTO #xhtmlEdicao VALUES ( '						<h:panelGrid columns="3" id="panel' + UPPER(substring(@tabelaNome, 1,1))  + substring(@tabelaNome, 2,len(@tabelaNome)) + '"> ')
	-----------------------------------------------------------------------------------------------------------
	--CURSOR que apresenta os dados das tabelas relacionadas a principal
	-----------------------------------------------------------------------------------------------------------				
	DECLARE campos CURSOR FOR	SELECT									
								DISTINCT CASE ISNULL(pkt.NAME,'') WHEN '' THEN sc.name ELSE (lower(substring( pkt.NAME, 1,1))  + substring( pkt.NAME, 2,len( pkt.NAME))) END
								,CASE ISNULL(pkt.NAME,'') WHEN '' THEN sty.name ELSE REPLACE((Upper(substring(sc.name, 1,1))  + substring(sc.name, 2,len(sc.name))),'_id','') END										
																		
						FROM 
										sys.tables st Inner Join sys.columns sc
													ON st.object_id = sc.object_id
										INNER JOIN sys.systypes sty
													ON sc.system_type_id = sty.xtype
										LEFT JOIN	sys.foreign_key_columns fkc 
													ON fkc.parent_object_id = st.object_id 
													AND fkc.parent_column_id = sc.column_id 
										LEFT JOIN  sys.foreign_keys fk 
													ON fk.object_id = fkc.constraint_object_id
										LEFT JOIN sys.tables pkt
													ON fkc.referenced_object_id = pkt.object_id 
										LEFT JOIN sys.columns pkc
													ON pkt.object_id = pkc.object_id 
													AND fkc.referenced_column_id = pkc.column_id
						WHERE 
										st.name = @tabelaNome
										AND sc.name <> @entidade
										AND sc.is_identity = 0										
						--ORDER BY 
						--				st.Name ASC, 
						--				sc.column_id ASC		
	OPEN campos
	FETCH NEXT FROM campos into @colunaNome, @tipoDado;
	WHILE @@FETCH_STATUS = 0
	BEGIN						
			
		IF(UPPER(@tipoDado) = UPPER(@colunaNome) )
		BEGIN
		-----------------------------------------------------------------------------------------------------------
		--Gerando selectOneMenu a partir das tabelas de dados hardcode
		-----------------------------------------------------------------------------------------------------------
			INSERT INTO #xhtmlEdicao VALUES ( '							<caesb:linhaForm label="' + Upper(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+':" '+ 
															'id="' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+'"> ')
			INSERT INTO #xhtmlEdicao VALUES ( '								<p:selectOneMenu value="#{bean.' + LOWER(substring(@tabelaNome, 1,1))  + substring(@tabelaNome, 2,len(@tabelaNome))+ '.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+'}" converter="#{' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+'Converter}"> ')
			INSERT INTO #xhtmlEdicao VALUES ( '									<f:selectItem itemLabel="Selecione " /> ')
			INSERT INTO #xhtmlEdicao VALUES ( '									<f:selectItems value="#{bean.registros' + Upper(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome)) + '}" var="' + SUBSTRING(LOWER(@colunaNome),1,3) + '" itemLabel="#{' + SUBSTRING(LOWER(@colunaNome),1,3) + '.descricao}" itemValue="#{' + SUBSTRING(LOWER(@colunaNome),1,3) + '}"/> ')
			INSERT INTO #xhtmlEdicao VALUES ( '								</p:selectOneMenu> ')
			INSERT INTO #xhtmlEdicao VALUES ( '							</caesb:linhaForm> ')
		END
		ELSE IF (UPPER(@tipoDado) = 'date' OR UPPER(@tipoDado) = 'time' OR UPPER(@tipoDado) = 'timestamp' 
					OR UPPER(@tipoDado) = 'datetime2' OR UPPER(@tipoDado) = 'datetimeoffset' 
					OR UPPER(@tipoDado) = 'smalldatetime' OR UPPER(@tipoDado) = 'datetime')
		BEGIN
		-----------------------------------------------------------------------------------------------------------
		--Gerando calendar a partir de campos de data
		-----------------------------------------------------------------------------------------------------------
			INSERT INTO #xhtmlEdicao VALUES ( '							<caesb:linhaForm label="' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+':"> ')
			INSERT INTO #xhtmlEdicao VALUES ( '								<p:calendar locale="pt" value="#{bean.' + LOWER(substring(@tabelaNome, 1,1))  + substring(@tabelaNome, 2,len(@tabelaNome))+ '.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+'}" navigator="true" yearRange="1930:2050" ')
			INSERT INTO #xhtmlEdicao VALUES ( '						id="' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+
																'" showOn="button" required="true" readOnlyInputText="true" ')
			INSERT INTO #xhtmlEdicao VALUES ( '						pattern="dd/MM/yyyy" showButtonPanel="true" size="9" maxlength="10" > ')
			INSERT INTO #xhtmlEdicao VALUES ( '								</p:calendar>')
			INSERT INTO #xhtmlEdicao VALUES ( '							</caesb:linhaForm> ')
		END
		--ELSE IF (UPPER(@tipoDado) = 'real' OR UPPER(@tipoDado) = 'money'  OR UPPER(@tipoDadp) = 'float' 
		--			OR UPPER(@tipoDado) = 'decimal' OR UPPER(@tipoDado) = 'smallmoney')
		--BEGIN
		-----------------------------------------------------------------------------------------------------------
		--Gerando inputNumber a partir de campos de valor monetário
		-----------------------------------------------------------------------------------------------------------						
		--END
		ELSE IF(UPPER(@tipoDado) = 'bit')
		BEGIN
		-----------------------------------------------------------------------------------------------------------
		--Gerando selectBooleanCheckbox a partir dcampos booleanos
		-----------------------------------------------------------------------------------------------------------
			INSERT INTO #xhtmlEdicao VALUES ( '							<caesb:linhaForm label="' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+':"> ')
			INSERT INTO #xhtmlEdicao VALUES ( '								<p:selectBooleanCheckbox id="' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+'" ' +  
															'value="#{bean.' + LOWER(substring(@tabelaNome, 1,1))  + substring(@tabelaNome, 2,len(@tabelaNome))+ '.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+'}" />')
			--INSERT INTO #xhtml VALUES ( '						</p:selectBooleanCheckbox> ')
			INSERT INTO #xhtmlEdicao VALUES ( '							</caesb:linhaForm> ')				
		END
		ELSE
		BEGIN
		-----------------------------------------------------------------------------------------------------------
		--Gerando inputText a partir de campos 
		-----------------------------------------------------------------------------------------------------------
			INSERT INTO #xhtmlEdicao VALUES ( '							<caesb:linhaForm label="' + Upper(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+ ':"> ')
			INSERT INTO #xhtmlEdicao VALUES ( '								<p:inputText id="' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+ '" value="#{bean.' + LOWER(substring(@tabelaNome, 1,1))  + substring(@tabelaNome, 2,len(@tabelaNome))+ '.' + LOWER(substring(@colunaNome, 1,1))  + substring(@colunaNome, 2,len(@colunaNome))+ '}"  /> ')
			INSERT INTO #xhtmlEdicao VALUES ( '							</caesb:linhaForm> ')	
		END		
		FETCH NEXT FROM campos INTO @colunaNome, @tipoDado;		
	END;
	CLOSE campos;
	DEALLOCATE campos;
	-----------------------------------------------------------------------------------------------------------
	--Fechando o panel da tabela principal
	-----------------------------------------------------------------------------------------------------------	
	
	INSERT INTO #xhtmlEdicao VALUES ( '						</h:panelGrid> ')
	INSERT INTO #xhtmlEdicao VALUES ( '						<h:panelGrid columns="1"> ')
	INSERT INTO #xhtmlEdicao VALUES ( '							<p:commandButton icon="ui-icon-check" actionListener="#{bean.inserir' + Upper(substring(@tabelaNome, 1,1))  + substring(@tabelaNome, 2,len(@tabelaNome)) + '()}" process=":formEdicao:panel' + Upper(substring(@tabelaNome, 1,1))  + substring(@tabelaNome, 2,len(@tabelaNome)) + '" update=":formEdicao:panel' + Upper(substring(@tabelaNome, 1,1))  + substring(@tabelaNome, 2,len(@tabelaNome)) + '" /> ')
	INSERT INTO #xhtmlEdicao VALUES ( '						</h:panelGrid> ')
	

	INSERT INTO #xhtmlEdicao VALUES ( '						<p:dataTable var="item" value="#{bean.entidade.registros' + Upper(substring(@tabelaNome, 1,1))  + substring(@tabelaNome, 2,len(@tabelaNome)) + '}" emptyMessage="Nenhum ' + @tabelaNome + '"> ')

	DECLARE campos CURSOR FOR	SELECT									
								DISTINCT st.name
								,CASE ISNULL(pkt.NAME,'') WHEN '' THEN sc.name ELSE (lower(substring( pkt.NAME, 1,1))  + substring( pkt.NAME, 2,len( pkt.NAME))) END
								,CASE ISNULL(pkt.NAME,'') WHEN '' THEN sty.name ELSE REPLACE((Upper(substring(sc.name, 1,1))  + substring(sc.name, 2,len(sc.name))),'_id','') END										
																		
						FROM 
										sys.tables st Inner Join sys.columns sc
													ON st.object_id = sc.object_id
										INNER JOIN sys.systypes sty
													ON sc.system_type_id = sty.xtype
										LEFT JOIN	sys.foreign_key_columns fkc 
													ON fkc.parent_object_id = st.object_id 
													AND fkc.parent_column_id = sc.column_id 
										LEFT JOIN  sys.foreign_keys fk 
													ON fk.object_id = fkc.constraint_object_id
										LEFT JOIN sys.tables pkt
													ON fkc.referenced_object_id = pkt.object_id 
										LEFT JOIN sys.columns pkc
													ON pkt.object_id = pkc.object_id 
													AND fkc.referenced_column_id = pkc.column_id
						WHERE 
										st.name = @tabelaNome										
										AND sc.is_identity = 0
						--ORDER BY 
						--				st.Name ASC, 
						--				sc.column_id ASC		
	OPEN campos
	FETCH NEXT FROM campos into @tabelaNome, @colunaNome, @tipoDado;
	WHILE @@FETCH_STATUS = 0
	BEGIN						
		print (@tabelaNome)
		INSERT INTO #xhtmlEdicao VALUES ( '							<p:column headerText="' + LOWER(substring(@tipoDado, 1,1))  + substring(@tipoDado, 2,len(@tipoDado)) + '">#{item.' + LOWER(substring(@tipoDado, 1,1))  + substring(@tipoDado, 2,len(@tipoDado)) + '}</p:column> ')

		FETCH NEXT FROM campos INTO @tabelaNome, @colunaNome, @tipoDado;		
	END;
	CLOSE campos;
	DEALLOCATE campos;
	
	
	INSERT INTO #xhtmlEdicao VALUES ( '							<p:column styleClass="menuBotoes" width="10%"> ')
	INSERT INTO #xhtmlEdicao VALUES ( '								<caesb:menuButton> ')
	INSERT INTO #xhtmlEdicao VALUES ( '									<p:menuitem icon="ui-icon-pencil" /> ')
	INSERT INTO #xhtmlEdicao VALUES ( '									<p:menuitem icon="ui-icon-trash" /> ')
	INSERT INTO #xhtmlEdicao VALUES ( '								</caesb:menuButton> ')
	INSERT INTO #xhtmlEdicao VALUES ( '							</p:column> ')
	INSERT INTO #xhtmlEdicao VALUES ( '						</p:dataTable> ')


	

									
	INSERT INTO #xhtmlEdicao VALUES ( '					</p:panel>')

	SET @i = @i +1;		
	FETCH NEXT FROM hashset INTO @tabelaNome,@j;	
	IF((@i > 0 AND @i%2=0) OR @i = @j)
	BEGIN			
		INSERT INTO #xhtmlEdicao VALUES ( '				</h:panelGroup>')	
	END
END;	
CLOSE hashset;
DEALLOCATE hashset;		
-----------------------------------------------------------------------------------------------------------
--Fechando o panelGrid
-----------------------------------------------------------------------------------------------------------
INSERT INTO #xhtmlEdicao VALUES ( '			</h:panelGrid>')
INSERT INTO #xhtmlEdicao VALUES ('			<p>')
INSERT INTO #xhtmlEdicao VALUES ('			<center>')
INSERT INTO #xhtmlEdicao VALUES ('				<p:commandButton value="Salvar" actionListener="#{bean.cadastrar}" update=":formPesquisa,formEdicao"' +
					' rendered="#{bean.entidade.id eq null}" oncomplete="if(args.fechar) PF''(dlg' + UPPER(substring(@entidade, 1,1))  + substring(@entidade, 2,len(@entidade)) +''').hide()" />')
INSERT INTO #xhtmlEdicao VALUES ('')
INSERT INTO #xhtmlEdicao VALUES ('				<p:commandButton value="Salvar" actionListener="#{bean.alterar}" update=":formPesquisa,formEdicao" rendered="#{bean.entidade.id ne null}" ' +
					' oncomplete="if(args.fechar) PF''(dlg' + UPPER(substring(@entidade, 1,1))  + substring(@entidade, 2,len(@entidade)) +''').hide()" />')
INSERT INTO #xhtmlEdicao VALUES ('			</center>')
INSERT INTO #xhtmlEdicao VALUES ('			</p>')
INSERT INTO #xhtmlEdicao VALUES ('		</h:form>')
INSERT INTO #xhtmlEdicao VALUES ('	</p:dialog>')
INSERT INTO #xhtmlEdicao VALUES ('</ui:fragment>')
-----------------------------------------------------------------------------------------------------------
--Select que apresentará o resultado
-----------------------------------------------------------------------------------------------------------
SELECT * FROM #xhtmlEdicao