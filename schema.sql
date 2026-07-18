-- -----------------------------------------------------
-- Table `gerenciamento_fila2`.`Usuario`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `gerenciamento_fila2`.`Usuario` (
  `cpf_usuario` CHAR(11) NOT NULL,
  `email_usuario` VARCHAR(150) NOT NULL,
  `senha_usuario` VARCHAR(255) NOT NULL,
  `nome_usuario` VARCHAR(150) NOT NULL,
  `especialidade_usuario` VARCHAR(100) NULL DEFAULT NULL,
  `telefone_usuario` VARCHAR(20) NULL DEFAULT NULL,
  `data_nascimento_usuario` DATE NULL DEFAULT NULL,
  `ativo_usuario` TINYINT(1) NULL DEFAULT 1,
  `criado_em_usuario` DATETIME NULL DEFAULT CURRENT_TIMESTAMP(),
  PRIMARY KEY (`cpf_usuario`),
  UNIQUE INDEX `uq_email_usuario` (`email_usuario` ASC) VISIBLE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;


-- -----------------------------------------------------
-- Table `gerenciamento_fila2`.`Unidade`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `gerenciamento_fila2`.`Unidade` (
  `id_unidade` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `nome_unidade` VARCHAR(150) NOT NULL,
  `endereco_unidade` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id_unidade`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;


-- -----------------------------------------------------
-- Table `gerenciamento_fila2`.`Mutirao`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `gerenciamento_fila2`.`Mutirao` (
  `id_mutirao` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_unidade` INT(10) UNSIGNED NOT NULL,
  `data_mutirao` DATE NOT NULL,
  `tipo_mutirao` VARCHAR(45) NOT NULL,
  `local_mutirao` VARCHAR(200) NOT NULL,
  `duracao_min_mutirao` INT(11) NOT NULL,
  `status_mutirao` ENUM('aberto', 'encerrado') NOT NULL DEFAULT 'aberto',
  `criado_em_mutirao` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  PRIMARY KEY (`id_mutirao`),
  INDEX `idx_mutirao_unidade` (`id_unidade` ASC) VISIBLE,
  CONSTRAINT `fk_mutirao_unidade`
    FOREIGN KEY (`id_unidade`)
    REFERENCES `gerenciamento_fila2`.`Unidade` (`id_unidade`)
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;


-- -----------------------------------------------------
-- Table `gerenciamento_fila2`.`Fila`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `gerenciamento_fila2`.`Fila` (
  `id_fila` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_mutirao` INT(10) UNSIGNED NOT NULL,
  `nome_fila` VARCHAR(100) NOT NULL,
  `tipo_fila` ENUM('comum', 'prioritario') NOT NULL,
  PRIMARY KEY (`id_fila`),
  INDEX `idx_fila_mutirao` (`id_mutirao` ASC) VISIBLE,
  CONSTRAINT `fk_fila_mutirao`
    FOREIGN KEY (`id_mutirao`)
    REFERENCES `gerenciamento_fila2`.`Mutirao` (`id_mutirao`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;


-- -----------------------------------------------------
-- Table `gerenciamento_fila2`.`ItemFila`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `gerenciamento_fila2`.`ItemFila` (
  `id_fila` INT(10) UNSIGNED NOT NULL,
  `cpf_usuario` CHAR(11) NOT NULL,
  `sequencia_item_fila` INT(10) UNSIGNED NOT NULL,
  `status_itemfila` ENUM('aguardando', 'chamado', 'em_atendimento', 'atendido', 'ausente') NULL DEFAULT 'aguardando',
  `entrada_em_item_fila` DATETIME NULL DEFAULT CURRENT_TIMESTAMP(),
  `atualizado_em_item_fila` DATETIME NULL DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP(),
  UNIQUE INDEX `uq_fila_sequencia` (`id_fila` ASC, `sequencia_item_fila` ASC) VISIBLE,
  INDEX `idx_itemfila_usuario` (`cpf_usuario` ASC) VISIBLE,
  PRIMARY KEY (`id_fila`, `sequencia_item_fila`),
  CONSTRAINT `fk_itemfila_fila`
    FOREIGN KEY (`id_fila`)
    REFERENCES `gerenciamento_fila2`.`Fila` (`id_fila`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_itemfila_usuario`
    FOREIGN KEY (`cpf_usuario`)
    REFERENCES `gerenciamento_fila2`.`Usuario` (`cpf_usuario`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;


-- -----------------------------------------------------
-- Table `gerenciamento_fila2`.`Atendimento`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `gerenciamento_fila2`.`Atendimento` (
  `id_atendimento` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_item_fila` INT(10) UNSIGNED NOT NULL,
  `cpf_usuario` CHAR(11) NOT NULL,
  `inicio_atendimento` DATETIME NOT NULL,
  `fim_atendimento` DATETIME NULL DEFAULT NULL,
  `id_fila` INT(10) UNSIGNED NOT NULL,
  `sequencia_item_fila` INT(10) UNSIGNED NOT NULL,
  PRIMARY KEY (`id_atendimento`),
  INDEX `idx_atendimento_usuario` (`cpf_usuario` ASC) VISIBLE,
  INDEX `fk_Atendimento_ItemFila1_idx` (`id_fila` ASC, `sequencia_item_fila` ASC) VISIBLE,
  CONSTRAINT `fk_atendimento_usuario`
    FOREIGN KEY (`cpf_usuario`)
    REFERENCES `gerenciamento_fila2`.`Usuario` (`cpf_usuario`)
    ON UPDATE CASCADE,
  CONSTRAINT `fk_Atendimento_ItemFila1`
    FOREIGN KEY (`id_fila` , `sequencia_item_fila`)
    REFERENCES `gerenciamento_fila2`.`ItemFila` (`id_fila` , `sequencia_item_fila`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;


-- -----------------------------------------------------
-- Table `gerenciamento_fila2`.`Documento`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `gerenciamento_fila2`.`Documento` (
  `id_documento` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `cpf_usuario` CHAR(11) NOT NULL,
  `tipo_documento` ENUM('relatorio', 'exame', 'outro') NULL DEFAULT NULL,
  `arquivo_url_documento` VARCHAR(500) NULL DEFAULT NULL,
  `status_validacao_documento` ENUM('pendente', 'aprovado', 'rejeitado') NULL DEFAULT 'pendente',
  `validado_por_usuario` CHAR(11) NULL DEFAULT NULL,
  `validado_em_documento` DATETIME NULL DEFAULT NULL,
  `enviado_em_documento` DATETIME NULL DEFAULT CURRENT_TIMESTAMP(),
  PRIMARY KEY (`id_documento`),
  INDEX `idx_documento_usuario` (`cpf_usuario` ASC) VISIBLE,
  INDEX `idx_documento_validador` (`validado_por_usuario` ASC) VISIBLE,
  CONSTRAINT `fk_documento_usuario`
    FOREIGN KEY (`cpf_usuario`)
    REFERENCES `gerenciamento_fila2`.`Usuario` (`cpf_usuario`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_documento_validador`
    FOREIGN KEY (`validado_por_usuario`)
    REFERENCES `gerenciamento_fila2`.`Usuario` (`cpf_usuario`)
    ON DELETE SET NULL
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;


-- -----------------------------------------------------
-- Table `gerenciamento_fila2`.`UsuarioMutirao`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `gerenciamento_fila2`.`UsuarioMutirao` (
  `cpf_usuario` CHAR(11) NOT NULL,
  `id_mutirao` INT(10) UNSIGNED NOT NULL,
  `criou_mutirao` TINYINT NOT NULL,
  PRIMARY KEY (`cpf_usuario`, `id_mutirao`),
  INDEX `fk_usuario_mutirao_mutirao` (`id_mutirao` ASC) VISIBLE,
  CONSTRAINT `fk_usuario_mutirao_mutirao`
    FOREIGN KEY (`id_mutirao`)
    REFERENCES `gerenciamento_fila2`.`Mutirao` (`id_mutirao`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_usuario_mutirao_usuario`
    FOREIGN KEY (`cpf_usuario`)
    REFERENCES `gerenciamento_fila2`.`Usuario` (`cpf_usuario`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;


-- -----------------------------------------------------
-- Table `gerenciamento_fila2`.`UsuarioPerfil`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `gerenciamento_fila2`.`UsuarioPerfil` (
  `id_perfil` INT NOT NULL,
  `cpf_usuario` CHAR(11) NOT NULL,
  `tipo_perfil` ENUM('Paciente', 'Atendente', 'Medico', 'Adm_unidade', 'Adm_geral') NOT NULL,
  PRIMARY KEY (`id_perfil`, `cpf_usuario`),
  CONSTRAINT `fk_usuario_perfil_usuario`
    FOREIGN KEY (`cpf_usuario`)
    REFERENCES `gerenciamento_fila2`.`Usuario` (`cpf_usuario`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;


-- -----------------------------------------------------
-- Table `gerenciamento_fila2`.`UsuarioUnidade`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `gerenciamento_fila2`.`UsuarioUnidade` (
  `cpf_usuario` CHAR(11) NOT NULL,
  `id_unidade` INT(10) UNSIGNED NOT NULL,
  PRIMARY KEY (`cpf_usuario`, `id_unidade`),
  INDEX `fk_usuario_unidade_unidade` (`id_unidade` ASC) VISIBLE,
  CONSTRAINT `fk_usuario_unidade_unidade`
    FOREIGN KEY (`id_unidade`)
    REFERENCES `gerenciamento_fila2`.`Unidade` (`id_unidade`)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT `fk_usuario_unidade_usuario`
    FOREIGN KEY (`cpf_usuario`)
    REFERENCES `gerenciamento_fila2`.`Usuario` (`cpf_usuario`)
    ON DELETE CASCADE
    ON UPDATE CASCADE)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;
