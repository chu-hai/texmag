PROGRAM   = texmag
SOURCES   = main.vala data_stores.vala thumbnail_frame.vala utils.vala settings.vala image_file_monitor.vala info_message.vala
RESOURCES = resources.xml
PKGS      = glib-2.0 gobject-2.0 gtk+-3.0 gio-2.0
VALAFLAGS =

WORK_DIR  = .vala_work/
RES_DIR   = resources/
VALAC     = valac

_VFLAGS   = $(VALAFLAGS) $(addprefix --pkg , $(PKGS))
_LDFLAGS  = `pkg-config --libs $(PKGS)`

BASENAMES      = $(notdir $(basename $(SOURCES)))
FASTVAPI_FILES = $(foreach f, $(BASENAMES), $(WORK_DIR)$(f).vapi)
FASTVAPI_STAMP = $(foreach f, $(BASENAMES), $(WORK_DIR)$(f).vapi.stamp)
C_FILES        = $(foreach f, $(BASENAMES), $(WORK_DIR)$(f).c)
OBJ_FILES      = $(foreach f, $(BASENAMES), $(WORK_DIR)$(f).o)

RES_BASENAMES  = $(notdir $(basename $(RESOURCES)))
RES_OBJ_FILES  = $(foreach f, $(RES_BASENAMES), $(WORK_DIR)$(f).o)
RES_DATA_FILES = $(wildcard $(RES_DIR)/*)

.PRECIOUS: $(WORK_DIR)%.vapi $(WORK_DIR)%.vapi.stamp $(WORK_DIR)%.dep \
		   $(WORK_DIR)%.c $(WORK_DIR)%.res.c $(WORK_DIR)%.o

.PHONY: all
all: $(PROGRAM)

$(PROGRAM): $(OBJ_FILES) $(RES_OBJ_FILES)
	@echo '  BUILD '$@
	@$(CC) -o $@ $(_LDFLAGS) $^

$(WORK_DIR)%.vapi: ;

$(WORK_DIR)%.vapi.stamp: %.vala | $(WORK_DIR)
	@echo '  GEN   '$(WORK_DIR)$*.vapi
	@touch $(WORK_DIR)$*.vapi.stamp
	@$(VALAC) --fast-vapi=$(WORK_DIR)$*.vapi $<

$(WORK_DIR)%.dep $(WORK_DIR)%.c: %.vala | $(FASTVAPI_STAMP)
	@echo '  GEN   '$(WORK_DIR)$*.c
	@$(VALAC) -C --deps=$(WORK_DIR)$*.dep $(_VFLAGS) -d $(WORK_DIR) $(addprefix --use-fast-vapi=,$(subst $(WORK_DIR)$*.vapi,, $(FASTVAPI_FILES))) $< && touch $(WORK_DIR)$*.c

$(WORK_DIR)%.o: $(WORK_DIR)%.c | $(FASTVAPI_STAMP)
	@echo '  GEN   '$@
	@$(VALAC) -c $(_VFLAGS) $(WORK_DIR)$*.c
	@mv $*.o $(WORK_DIR)

$(WORK_DIR)%.res.c: %.xml $(RES_DATA_FILES)
	@echo '  GEN   '$@
	@glib-compile-resources --generate-source --target $(WORK_DIR)$*.res.c $<

$(WORK_DIR)%.o: $(WORK_DIR)%.res.c
	@echo '  GEN   '$@
	@$(VALAC) -c $(_VFLAGS) $(WORK_DIR)$*.res.c
	@mv $*.res.o $@

$(WORK_DIR):
	@mkdir -p $(WORK_DIR)

include $(wildcard $(WORK_DIR)/*.dep)

.PHONY: clean
clean:
	@rm -vf $(PROGRAM)
	@rm -vrf $(WORK_DIR)
