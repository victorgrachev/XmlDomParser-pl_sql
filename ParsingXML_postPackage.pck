create or replace package ParsingXML_postPackage is

  -- Author  : Grachev V.T
  -- Created : 30.11.2019 14:13:09
  /*
  ����� �������� �� ������ DOM ������� Oracle
  ����� ������������ ��� ������� XML ������:
  -- ��������� �������� XML �� �������� ����� - GetClobOutBfile (��� �����, ��� ����������, Clob ������������ ����������)
  -- ��������� ������� CLOB XML ����� -  ParsingXml(Clob ���� ��� �������)
  -- �������������� ������ �������� vXMLsPars
  */
  type tabAttr is table of varchar2(1000) index by varchar2(1000);
  type tabTagValue is table of varchar2(1000) index by varchar2(1000);
  
  type recXml is record (NameTag varchar2(1000)          -- ������������ ��������
                        , NameParentTag varchar2(1000)   -- ������������ ������������� ��������
                        , Attributes tabAttr             -- ������ ��������� ��������
                        , ValuesTag tabTagValue);        -- ������ �������� ��������
  type tabXml is table of recXml index by pls_integer;
  --------------------------------------------------------
  procedure GetClobOutBfile (pBfileName varchar2
                            , pNameDirect varchar2
                            , pClobOut out Clob);
   --------------------------------------------------------                        
  procedure ParsingXml(pClob clob);
   --------------------------------------------------------
  vXMLsPars tabXml; 

end ParsingXML_postPackage;
/
create or replace package body ParsingXML_postPackage is
  -------------------------------------------------------------------- 
  procedure GetClobOutBfile (pBfileName varchar2
                            , pNameDirect varchar2
                            , pClobOut out Clob)
    is
     vInBfile bfile;
     vDestination_offset integer := 1;
     vSource_offset integer := 1;
     vlang_context integer := 1;
     vWarning integer;
    begin
      dbms_lob.createtemporary(lob_loc => pClobOut,
                               cache   => True,
                               dur     => DBMS_LOB.session);
      vInBfile := BFILENAME(pNameDirect, pBfileName);
      dbms_lob.open(pClobOut, DBMS_LOB.LOB_READWRITE);
      dbms_lob.open(vInBfile);
      dbms_lob.loadclobfromfile(dest_lob     => pClobOut,
                                src_bfile    => vInBfile,
                                amount       => DBMS_LOB.LOBMAXSIZE,
                                dest_offset  => vDestination_offset,
                                src_offset   => vSource_offset,
                                bfile_csid   => 1,
                                lang_context => vlang_context,
                                warning      => vWarning);
      dbms_lob.close(pClobOut);
      dbms_lob.close(vInBfile);
    exception
      null;
      --todo ��������� ������ �������� ������ � �������
    end GetClobOutBfile;
  ------------------------------------------------------------------------
  procedure ParsingNode(pNodeList dbms_xmldom.DOMNodeList)
    is
       vNode dbms_xmldom.DOMNode;
       vCheckChildNodes dbms_xmldom.DOMNodeList;
       vAttrs dbms_xmldom.DOMNamedNodeMap;
       vAtr dbms_xmldom.DOMNode;
       
       vCheckNodeList number;
    begin
      vCheckNodeList := dbms_xmldom.getLength(pNodeList);
      if vCheckNodeList > 0 then
        for i in 0 .. vCheckNodeList - 1 loop
          vNode := dbms_xmldom.item(pNodeList, i);
          vXMLsPars(vXMLsPars.count+1).NameTag := dbms_xmldom.getNodeName(vNode);
          vXMLsPars(vXMLsPars.count).NameParentTag := dbms_xmldom.getNodeName(dbms_xmldom.getParentNode(vNode));
          -- ���� ���� �������� ������
          if dbms_xmldom.hasAttributes(vNode) then
            vAttrs := dbms_xmldom.getAttributes(vNode);
            for j in 0 .. dbms_xmldom.getLength(vAttrs) - 1 loop
              vAtr := dbms_xmldom.item(vAttrs, j);
              vXMLsPars(vXMLsPars.count).Attributes(dbms_xmldom.getNodeName(vAtr)) := dbms_xmldom.getNodeValue(vAtr);
            end loop;
          end if;
          -- ���� ���� �������� ���� � ��� �� ������ ���� � ���, ����� ����� �������� �����
          vCheckChildNodes := dbms_xmldom.getChildNodes(vNode);
          if dbms_xmldom.getNodeType(dbms_xmldom.item(vCheckChildNodes,0)) <> 3 then 
            ParsingNode(vCheckChildNodes);
          else
           vXMLsPars(vXMLsPars.count).ValuesTag(dbms_xmldom.getNodeName(vNode)) := dbms_xmldom.getNodeValue(dbms_xmldom.getFirstChild(vNode));
          end if;
        end loop;
      end if;
    end ParsingNode;
  ------------------------------------------------------------------------
  
  procedure ParsingXml(pClob clob) 
    is
     vParser               dbms_xmlparser.Parser;
     
     vDoc                  dbms_xmldom.DOMDocument;
     vRootElem             dbms_xmldom.DOMElement;
 
     vNodeList             dbms_xmldom.DOMNodeList;
     vNode                 dbms_xmldom.DOMNode;
     vAttributeList        dbms_xmldom.DOMNamedNodeMap;
     vAttribute            dbms_xmldom.DOMNode;    
    begin
      vParser := dbms_xmlparser.newParser;
      dbms_xmlparser.parseClob(vParser, pClob);
      
      vDoc := dbms_xmlparser.getDocument(vParser);
      vRootElem := dbms_xmldom.getDocumentElement(vDoc);
      
      vXMLsPars(vXMLsPars.count+1).NameTag := dbms_xmldom.getTagName(vRootElem);
      vNode := dbms_xmldom.makeNode(vRootElem);
      vAttributeList := dbms_xmldom.getAttributes(vNode);
      
      for i in 0 .. dbms_xmldom.getLength(vAttributeList) - 1 loop
        vAttribute := dbms_xmldom.item(vAttributeList, i);
        vXMLsPars(vXMLsPars.count).Attributes(dbms_xmldom.getNodeName(vAttribute)) := dbms_xmldom.getNodeValue(vAttribute);
        vXMLsPars(vXMLsPars.count).Attributes(dbms_xmldom.getNodeName(vAttribute)) := dbms_xmldom.getNodeValue(vAttribute);
      end loop;

      vNode := dbms_xmldom.makeNode(vRootElem);
      vNodeList := dbms_xmldom.getChildNodes(vNode);
      ParsingNode(vNodeList);
            
    end ParsingXml;

begin
  -- Initialization
  null;
end ParsingXML_postPackage;
/
