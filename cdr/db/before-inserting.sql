-- MySQL dump 10.13  Distrib 5.1.73, for redhat-linux-gnu (x86_64)
--
-- Host: localhost    Database: na62_bk
-- ------------------------------------------------------
-- Server version	5.1.73-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `burst`
--

DROP TABLE IF EXISTS `burst`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `burst` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `isdebug` tinyint(4) DEFAULT NULL,
  `number` bigint(20) DEFAULT NULL,
  `run_id` bigint(20) NOT NULL,
  `timestamp` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_burst_run1_idx` (`run_id`),
  CONSTRAINT `fk_burst_run1` FOREIGN KEY (`run_id`) REFERENCES `run` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `burst`
--

LOCK TABLES `burst` WRITE;
/*!40000 ALTER TABLE `burst` DISABLE KEYS */;
/*!40000 ALTER TABLE `burst` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `burstquality`
--

DROP TABLE IF EXISTS `burstquality`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `burstquality` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `burst_id` bigint(20) NOT NULL,
  `quality_id` bigint(20) NOT NULL,
  `timestamp` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_burstquality_burst1_idx` (`burst_id`),
  KEY `fk_burstquality_quality1_idx` (`quality_id`),
  CONSTRAINT `fk_burstquality_burst1` FOREIGN KEY (`burst_id`) REFERENCES `burst` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_burstquality_quality1` FOREIGN KEY (`quality_id`) REFERENCES `quality` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `burstquality`
--

LOCK TABLES `burstquality` WRITE;
/*!40000 ALTER TABLE `burstquality` DISABLE KEYS */;
/*!40000 ALTER TABLE `burstquality` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `farm2castor`
--

DROP TABLE IF EXISTS `farm2castor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `farm2castor` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `running` tinyint(4) DEFAULT '0',
  `timestart` datetime DEFAULT NULL,
  `timeend` datetime DEFAULT NULL,
  `filereplicasource_id` bigint(20) DEFAULT NULL,
  `error` tinyint(4) DEFAULT NULL,
  `filereplicatarget_id` bigint(20) DEFAULT NULL,
  `target_uri` varchar(1024) DEFAULT NULL,
  `node` varchar(45) NOT NULL,
  `user` varchar(45) DEFAULT NULL,
  `pid` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_process_filereplica_idx` (`filereplicasource_id`),
  KEY `fk_process_filereplica1_idx` (`filereplicatarget_id`),
  CONSTRAINT `fk_process_filereplicasource` FOREIGN KEY (`filereplicasource_id`) REFERENCES `filecopy` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_process_filereplicatarget` FOREIGN KEY (`filereplicatarget_id`) REFERENCES `filecopy` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `farm2castor`
--

LOCK TABLES `farm2castor` WRITE;
/*!40000 ALTER TABLE `farm2castor` DISABLE KEYS */;
/*!40000 ALTER TABLE `farm2castor` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `file`
--

DROP TABLE IF EXISTS `file`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `file` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `filename` varchar(255) DEFAULT NULL,
  `custodiallevel` int(11) DEFAULT NULL,
  `createtime` datetime DEFAULT NULL,
  `filetype_id` bigint(20) NOT NULL,
  `run_number` int(11) DEFAULT NULL,
  `burst_number` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `filename_UNIQUE` (`filename`),
  KEY `fk_file_filetype1_idx` (`filetype_id`),
  CONSTRAINT `fk_file_filetype1` FOREIGN KEY (`filetype_id`) REFERENCES `filetype` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `file`
--

LOCK TABLES `file` WRITE;
/*!40000 ALTER TABLE `file` DISABLE KEYS */;
/*!40000 ALTER TABLE `file` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `filecopy`
--

DROP TABLE IF EXISTS `filecopy`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `filecopy` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `uri` varchar(255) NOT NULL,
  `createtime` datetime NOT NULL,
  `file_id` bigint(20) NOT NULL,
  `deletetime` datetime DEFAULT NULL,
  `size` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_filereplica_file1_idx` (`file_id`),
  CONSTRAINT `fk_filereplica_file1` FOREIGN KEY (`file_id`) REFERENCES `file` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `filecopy`
--

LOCK TABLES `filecopy` WRITE;
/*!40000 ALTER TABLE `filecopy` DISABLE KEYS */;
/*!40000 ALTER TABLE `filecopy` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `filelineage`
--

DROP TABLE IF EXISTS `filelineage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `filelineage` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `description` varchar(1024) DEFAULT NULL,
  `father_id` bigint(20) NOT NULL,
  `son_id` bigint(20) NOT NULL,
  `createtime` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_filelineage_father_idx` (`father_id`),
  KEY `fk_filelineage_son_idx` (`son_id`),
  CONSTRAINT `fk_filelineage_father` FOREIGN KEY (`father_id`) REFERENCES `file` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_filelineage_son` FOREIGN KEY (`son_id`) REFERENCES `file` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `filelineage`
--

LOCK TABLES `filelineage` WRITE;
/*!40000 ALTER TABLE `filelineage` DISABLE KEYS */;
/*!40000 ALTER TABLE `filelineage` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `filetype`
--

DROP TABLE IF EXISTS `filetype`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `filetype` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `filetypename` varchar(255) DEFAULT NULL,
  `filetypeshort` varchar(32) NOT NULL,
  `isdata` tinyint(4) DEFAULT NULL,
  `hasversion` tinyint(4) DEFAULT NULL,
  `extension` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `filetypeshort_UNIQUE` (`filetypeshort`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `filetype`
--

LOCK TABLES `filetype` WRITE;
/*!40000 ALTER TABLE `filetype` DISABLE KEYS */;
INSERT INTO `filetype` VALUES (0,'RAW','RAW',1,0,'.dat'),(1,'LKR','LKR',1,0,'.lkr');
/*!40000 ALTER TABLE `filetype` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `info`
--

DROP TABLE IF EXISTS `info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `info` (
  `id` int(11) NOT NULL,
  `createtime` datetime DEFAULT NULL,
  `contact` varchar(255) DEFAULT NULL,
  `replica` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `info`
--

LOCK TABLES `info` WRITE;
/*!40000 ALTER TABLE `info` DISABLE KEYS */;
INSERT INTO `info` VALUES (0,'2014-07-09 14:59:59','paolo.valente@cern.ch',0);
/*!40000 ALTER TABLE `info` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `quality`
--

DROP TABLE IF EXISTS `quality`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `quality` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `description` varchar(2048) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `quality`
--

LOCK TABLES `quality` WRITE;
/*!40000 ALTER TABLE `quality` DISABLE KEYS */;
INSERT INTO `quality` VALUES (0,'GOOD','No error');
/*!40000 ALTER TABLE `quality` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `run`
--

DROP TABLE IF EXISTS `run`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `run` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `number` int(11) NOT NULL,
  `runtype_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `number_UNIQUE` (`number`),
  KEY `fk_run_runtype1_idx` (`runtype_id`),
  CONSTRAINT `fk_run_runtype1` FOREIGN KEY (`runtype_id`) REFERENCES `runtype` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `run`
--

LOCK TABLES `run` WRITE;
/*!40000 ALTER TABLE `run` DISABLE KEYS */;
/*!40000 ALTER TABLE `run` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `runquality`
--

DROP TABLE IF EXISTS `runquality`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `runquality` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `run_id` bigint(20) NOT NULL,
  `quality_id` bigint(20) NOT NULL,
  `timestamp` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_runquality_run1_idx` (`run_id`),
  KEY `fk_runquality_quality1_idx` (`quality_id`),
  CONSTRAINT `fk_runquality_quality1` FOREIGN KEY (`quality_id`) REFERENCES `quality` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_runquality_run1` FOREIGN KEY (`run_id`) REFERENCES `run` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `runquality`
--

LOCK TABLES `runquality` WRITE;
/*!40000 ALTER TABLE `runquality` DISABLE KEYS */;
/*!40000 ALTER TABLE `runquality` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `runtype`
--

DROP TABLE IF EXISTS `runtype`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `runtype` (
  `id` bigint(20) NOT NULL,
  `runtypename` varchar(32) NOT NULL,
  `runtypedesc` varchar(256) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `runtypename_UNIQUE` (`runtypename`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `runtype`
--

LOCK TABLES `runtype` WRITE;
/*!40000 ALTER TABLE `runtype` DISABLE KEYS */;
INSERT INTO `runtype` VALUES (0,'DEBUG_NA62','Debug run type'),(1,'DEBUG_NA62_DB','Debug run type for the DB');
/*!40000 ALTER TABLE `runtype` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-07-29 16:06:44
