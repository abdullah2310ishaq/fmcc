import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/format/name_initials.dart';
import 'package:doctor_app/src/core/logging/app_logger.dart';
import 'package:doctor_app/src/core/network/api_failure.dart';
import 'package:doctor_app/src/core/presentation/dialog_controller_scope.dart';
import 'package:doctor_app/src/core/reference/reference_models.dart';
import 'package:doctor_app/src/core/session/session_controller.dart';
import 'package:doctor_app/src/core/theme/app_colors.dart';
import 'package:doctor_app/src/features/patients/patient_api.dart';
import 'package:doctor_app/src/features/patients/patient_api_models.dart';

const int _kOtherChoiceId = -1;
const String _kOtherChoiceLabel = 'Other';

/// Family history tab — relatives by degree (1st / 2nd / 3rd) and their conditions.
class PatientFamilyHistorySection extends StatefulWidget {
  const PatientFamilyHistorySection({
    super.key,
    required this.patientId,
    required this.patientApi,
    required this.medicalConditions,
    required this.relationDegrees,
    this.readOnly = false,
    this.allowAdd = false,
    this.initialRelatives,
    this.onRelativesChanged,
  });

  final String patientId;
  final PatientApi patientApi;
  final List<NamedReferenceItem> medicalConditions;
  final List<NamedReferenceItem> relationDegrees;
  final bool readOnly;
  final bool allowAdd;
  final List<PatientFamilyRelativeRow>? initialRelatives;
  final ValueChanged<List<PatientFamilyRelativeRow>>? onRelativesChanged;

  @override
  State<PatientFamilyHistorySection> createState() =>
      _PatientFamilyHistorySectionState();
}

class _PatientFamilyHistorySectionState
    extends State<PatientFamilyHistorySection> {
  List<PatientFamilyRelativeRow> _relatives = const [];
  int? _degreeId;
  int _tempRelativeIdSeq = 0;

  bool _loaded = false;
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _degreeId = _firstPositiveId(widget.relationDegrees);
    final seeded = widget.initialRelatives;
    if (seeded != null) {
      _relatives = _enrichRelatives(seeded);
      _loaded = true;
    }
    _logFamilyState('initState');
    if (seeded == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_loadWhenReady());
      });
    }
  }

  Future<void> _loadWhenReady() async {
    if (widget.medicalConditions.isEmpty || widget.relationDegrees.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
    }
    await _load();
  }

  @override
  void didUpdateWidget(covariant PatientFamilyHistorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final refsArrived = oldWidget.relationDegrees.isEmpty &&
        widget.relationDegrees.isNotEmpty;
    final conditionsArrived = oldWidget.medicalConditions.isEmpty &&
        widget.medicalConditions.isNotEmpty;
    if (refsArrived || conditionsArrived) {
      _logFamilyState('didUpdateWidget (refs arrived)');
      setState(() {
        if (_degreeId == null && widget.relationDegrees.isNotEmpty) {
          _degreeId = _firstPositiveId(widget.relationDegrees);
        }
        _relatives = _enrichRelatives(_relatives);
      });
      if (_loaded) {
        unawaited(
          _load(keepOnEmpty: true, mergeWith: _relatives),
        );
      }
    } else if (_degreeId == null && widget.relationDegrees.isNotEmpty) {
      setState(() {
        _degreeId = _firstPositiveId(widget.relationDegrees);
      });
      AppLogger.instance.i(
        '[FamilyHistory] degreeId set from refs → $_degreeId',
      );
    }
  }

  int? _firstPositiveId(List<NamedReferenceItem> items) {
    for (final e in items) {
      if (e.id > 0) return e.id;
    }
    return null;
  }

  int _allocTempRelativeId() => --_tempRelativeIdSeq;

  void _logFamilyState(String where) {
    final degreeSummary = widget.relationDegrees
        .map((e) => '${e.id}:${e.name}')
        .join(', ');
    final conditionSummary = widget.medicalConditions
        .take(8)
        .map((e) => '${e.id}:${e.name}')
        .join(', ');
    AppLogger.instance.i(
      '[FamilyHistory] $where | patientId=${widget.patientId} '
      'relationDegrees=${widget.relationDegrees.length} '
      'medicalConditions=${widget.medicalConditions.length} '
      'degreeId=$_degreeId relatives=${_relatives.length} '
      'loaded=$_loaded loading=$_loading',
    );
    if (widget.relationDegrees.isEmpty) {
      AppLogger.instance.w(
        '[FamilyHistory] relationDegrees EMPTY at $where — dropdown/tabs will be blank',
      );
    } else {
      AppLogger.instance.i('[FamilyHistory] relationDegrees → $degreeSummary');
    }
    if (widget.medicalConditions.isEmpty) {
      AppLogger.instance.w(
        '[FamilyHistory] medicalConditions EMPTY at $where — condition dropdown will be blank',
      );
    } else {
      AppLogger.instance.i(
        '[FamilyHistory] medicalConditions (first 8) → $conditionSummary',
      );
    }
  }

  String _labelForId(List<NamedReferenceItem> items, int id) {
    for (final e in items) {
      if (e.id == id) return e.name;
    }
    return '';
  }

  List<PatientFamilyRelativeRow> _enrichRelatives(
    List<PatientFamilyRelativeRow> rows,
  ) {
    return rows
        .map((rel) {
          var degreeName = rel.relationDegreeName.trim();
          if (degreeName.isEmpty && rel.relationDegreeId > 0) {
            degreeName = _labelForId(widget.relationDegrees, rel.relationDegreeId);
          }

          final conditions = rel.conditions
              .map(_enrichCondition)
              .where((c) => c.displayConditionName.isNotEmpty)
              .toList(growable: false);

          return rel.copyWith(
            relationDegreeName: degreeName,
            conditions: conditions,
          );
        })
        .toList(growable: false);
  }

  PatientFamilyConditionRow _enrichCondition(PatientFamilyConditionRow c) {
    final custom = c.customConditionName.trim();
    if (custom.isNotEmpty) return c;

    var name = c.conditionName.trim();
    if (name.isEmpty && c.conditionId > 0) {
      name = _labelForId(widget.medicalConditions, c.conditionId);
    }
    if (name.isNotEmpty) {
      return c.copyWith(conditionName: name);
    }
    return c;
  }

  PatientFamilyConditionRow _mergeConditionPair(
    PatientFamilyConditionRow local,
    PatientFamilyConditionRow remote,
  ) {
    var out = remote;
    if (remote.conditionName.trim().isEmpty &&
        local.conditionName.trim().isNotEmpty) {
      out = out.copyWith(conditionName: local.conditionName);
    }
    if (remote.customConditionName.trim().isEmpty &&
        local.customConditionName.trim().isNotEmpty) {
      out = out.copyWith(customConditionName: local.customConditionName);
    }
    if (remote.conditionId <= 0 && local.conditionId > 0) {
      out = out.copyWith(conditionId: local.conditionId);
    }
    if (remote.relativeConditionId.startsWith('local-') &&
        local.relativeConditionId.isNotEmpty &&
        !local.relativeConditionId.startsWith('local-')) {
      out = out.copyWith(relativeConditionId: local.relativeConditionId);
    } else if (remote.relativeConditionId.trim().isEmpty &&
        local.relativeConditionId.trim().isNotEmpty) {
      out = out.copyWith(relativeConditionId: local.relativeConditionId);
    }
    return _enrichCondition(out);
  }

  void _applyRelatives(
    List<PatientFamilyRelativeRow> rows, {
    bool keepOnEmpty = false,
    List<PatientFamilyRelativeRow>? mergeWith,
  }) {
    var incoming = _enrichRelatives(rows);
    if (mergeWith != null && mergeWith.isNotEmpty) {
      incoming = _mergeRelatives(mergeWith, incoming);
    }
    setState(() {
      if (incoming.isNotEmpty || !keepOnEmpty) {
        _relatives = incoming;
      }
      _loaded = true;
    });
    widget.onRelativesChanged?.call(_relatives);
  }

  List<PatientFamilyRelativeRow> _mergeRelatives(
    List<PatientFamilyRelativeRow> local,
    List<PatientFamilyRelativeRow> remote,
  ) {
    if (remote.isEmpty) return local;

    final localById = {
      for (final r in local)
        if (r.relativeId > 0) r.relativeId: r,
    };
    final merged = <PatientFamilyRelativeRow>[];
    final seen = <int>{};

    for (final remoteRow in remote) {
      seen.add(remoteRow.relativeId);
      merged.add(_mergeRelativePair(localById[remoteRow.relativeId], remoteRow));
    }

    for (final localRow in local) {
      if (localRow.relativeId > 0 && seen.contains(localRow.relativeId)) {
        continue;
      }
      merged.add(localRow);
    }

    return _enrichRelatives(merged);
  }

  PatientFamilyRelativeRow _mergeRelativePair(
    PatientFamilyRelativeRow? local,
    PatientFamilyRelativeRow remote,
  ) {
    if (local == null) return remote;

    var out = remote;
    if (remote.relationDegreeId <= 0 && local.relationDegreeId > 0) {
      out = out.copyWith(
        relationDegreeId: local.relationDegreeId,
        relationDegreeName: local.relationDegreeName,
      );
    } else if (remote.relationDegreeName.trim().isEmpty &&
        local.relationDegreeName.trim().isNotEmpty) {
      out = out.copyWith(relationDegreeName: local.relationDegreeName);
    }

    if (remote.specificRelation.trim().isEmpty &&
        local.specificRelation.trim().isNotEmpty) {
      out = out.copyWith(specificRelation: local.specificRelation);
    }

    if (remote.conditions.isEmpty && local.conditions.isNotEmpty) {
      out = out.copyWith(conditions: local.conditions);
    } else if (remote.conditions.isNotEmpty && local.conditions.isNotEmpty) {
      out = out.copyWith(
        conditions: _mergeConditionLists(local.conditions, remote.conditions),
      );
    }

    return out;
  }

  List<PatientFamilyConditionRow> _mergeConditionLists(
    List<PatientFamilyConditionRow> local,
    List<PatientFamilyConditionRow> remote,
  ) {
    if (remote.isEmpty) return local.map(_enrichCondition).toList(growable: false);
    if (local.isEmpty) {
      return remote.map(_enrichCondition).toList(growable: false);
    }

    final usedRemote = <int>{};
    final merged = <PatientFamilyConditionRow>[];

    for (final localCond in local) {
      PatientFamilyConditionRow? match;
      for (var i = 0; i < remote.length; i++) {
        if (usedRemote.contains(i)) continue;
        final remoteCond = remote[i];
        final sameId = localCond.relativeConditionId.isNotEmpty &&
            localCond.relativeConditionId == remoteCond.relativeConditionId;
        final sameCondition = localCond.conditionId > 0 &&
            localCond.conditionId == remoteCond.conditionId;
        final sameCustom = localCond.customConditionName.trim().isNotEmpty &&
            localCond.customConditionName.trim() ==
                remoteCond.customConditionName.trim();
        if (sameId || sameCondition || sameCustom) {
          match = remoteCond;
          usedRemote.add(i);
          break;
        }
      }

      if (match != null) {
        merged.add(_mergeConditionPair(localCond, match));
      } else if (localCond.isDraft) {
        continue;
      } else {
        merged.add(localCond);
      }
    }

    for (var i = 0; i < remote.length; i++) {
      if (!usedRemote.contains(i)) {
        merged.add(_enrichCondition(remote[i]));
      }
    }

    return merged;
  }

  List<PatientFamilyRelativeRow> _markConditionsSaved(
    List<PatientFamilyRelativeRow> rows,
  ) {
    return rows
        .map((rel) {
          final conditions = rel.conditions
              .map((c) {
                if (!c.isDraft) return c;
                final key = c.conditionId > 0
                    ? 'c${c.conditionId}'
                    : 'x${c.customConditionName.trim()}';
                return c.copyWith(
                  relativeConditionId: 'local-${rel.relativeId}-$key',
                );
              })
              .toList(growable: false);
          return rel.copyWith(conditions: conditions);
        })
        .toList(growable: false);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: TextStyle(fontSize: 14.sp))),
    );
  }

  Future<void> _load({
    bool keepOnEmpty = false,
    List<PatientFamilyRelativeRow>? mergeWith,
  }) async {
    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) return;

    final previous = List<PatientFamilyRelativeRow>.from(_relatives);
    setState(() => _loading = true);
    try {
      AppLogger.instance.i(
        '[FamilyHistory] GET familyhistory/${widget.patientId}',
      );
      final data = await widget.patientApi.getFamilyHistory(
        patientId: widget.patientId,
        bearerToken: token,
      );
      if (!mounted) return;
      AppLogger.instance.i(
        '[FamilyHistory] loaded ${data?.relatives.length ?? 0} relative(s)',
      );
      _applyRelatives(
        data?.relatives ?? const [],
        keepOnEmpty: keepOnEmpty,
        mergeWith: mergeWith ?? previous,
      );
      _logFamilyState('after _load');
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      AppLogger.instance.e('[FamilyHistory] _load failed: $e');
      _toast(session.apiClient.mapError(e).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<PatientFamilyRelativeRow> _relativesForDegree() {
    final d = _degreeId;
    if (d == null || d <= 0) return _relatives;

    final matched =
        _relatives.where((r) => r.relationDegreeId == d).toList();
    if (matched.isNotEmpty) return matched;

    final unassigned =
        _relatives.where((r) => r.relationDegreeId <= 0).toList();
    if (unassigned.isNotEmpty) return unassigned;

    return matched;
  }

  int _globalIndexFor(PatientFamilyRelativeRow row) {
    return _relatives.indexWhere((r) => r.relativeId == row.relativeId);
  }

  Future<void> _save() async {
    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) {
      _toast('Please sign in again.');
      return;
    }

    setState(() => _saving = true);
    try {
      var relatives = List<PatientFamilyRelativeRow>.from(_relatives);

      for (var i = 0; i < relatives.length; i++) {
        final rel = relatives[i];
        if (rel.relativeId > 0) continue;
        if (rel.relationDegreeId <= 0) {
          _toast('Each relative needs a relation degree.');
          return;
        }
        final body = <String, dynamic>{
          'patientId': widget.patientId,
          'relationDegreeId': rel.relationDegreeId,
        };
        final spec = rel.specificRelation.trim();
        if (spec.isNotEmpty) body['specificRelation'] = spec;

        final newId = await widget.patientApi.postFamilyRelative(
          body: body,
          bearerToken: token,
        );
        relatives[i] = rel.copyWith(relativeId: newId);
      }

      for (final rel in relatives) {
        final pending =
            rel.conditions.where((c) => c.isDraft).toList(growable: false);
        if (pending.isEmpty) continue;

        final batch = <Map<String, dynamic>>[];
        for (final c in pending) {
          if (c.isCustomCondition || c.conditionId == _kOtherChoiceId) {
            final custom = c.customConditionName.trim();
            if (custom.isEmpty) {
              _toast('Enter a custom condition name for each “Other” entry.');
              return;
            }
            batch.add({'customConditionName': custom});
          } else if (c.conditionId > 0) {
            batch.add({'conditionId': c.conditionId});
          }
        }
        if (batch.isNotEmpty) {
          await widget.patientApi.postFamilyRelativeConditions(
            relativeId: rel.relativeId,
            body: batch,
            bearerToken: token,
          );
        }
      }

      if (!mounted) return;
      final saved = _markConditionsSaved(_enrichRelatives(relatives));
      setState(() => _relatives = saved);
      _toast('Family history saved.');
      await _load(keepOnEmpty: true, mergeWith: saved);
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmDelete({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 18.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48.r,
                      height: 48.r,
                      decoration: BoxDecoration(
                        color: AppColors.dashboardPeach.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 28.sp,
                        color: AppColors.dashboardPrimaryDark,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dashboardPrimaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 22.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dashboardPrimaryDark,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  Future<void> _addRelative() async {
    _logFamilyState('before _addRelative');
    final defaultDegree = _degreeId ?? _firstPositiveId(widget.relationDegrees);
    if (defaultDegree == null || widget.relationDegrees.isEmpty) {
      AppLogger.instance.w(
        '[FamilyHistory] _addRelative blocked — relationDegrees empty or no valid id',
      );
      _toast('Relation degree list is still loading or empty.');
      return;
    }

    int relationDegreeId = defaultDegree;
    String relationDegreeName =
        _labelForId(widget.relationDegrees, defaultDegree);

    final row = await showDialog<PatientFamilyRelativeRow>(
      context: context,
      builder: (dialogCtx) {
        return DialogControllerScope(
          controllerCount: 1,
          builder: (context, ctrls) {
            final specificCtl = ctrls[0];
            return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(
                'Add family relative',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: relationDegreeId,
                      isExpanded: true,
                      decoration: _fieldDecoration(hint: 'Relation degree'),
                      items: widget.relationDegrees
                          .where((e) => e.id > 0)
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setLocal(() {
                          relationDegreeId = v;
                          relationDegreeName =
                              _labelForId(widget.relationDegrees, v);
                        });
                      },
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: specificCtl,
                      decoration: _fieldDecoration(
                        hint: 'Specific relation (e.g. Father, Mother)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogCtx,
                      PatientFamilyRelativeRow(
                        relativeId: _allocTempRelativeId(),
                        patientId: widget.patientId,
                        relationDegreeId: relationDegreeId,
                        relationDegreeName: relationDegreeName,
                        specificRelation: specificCtl.text.trim(),
                        conditions: const [],
                      ),
                    );
                  },
                  child: const Text('Add relative'),
                ),
              ],
            );
          },
            );
          },
        );
      },
    );

    if (row == null || !mounted) return;
    setState(() {
      _degreeId = row.relationDegreeId;
      _relatives = [..._relatives, row];
    });
    if (widget.readOnly && widget.allowAdd) {
      unawaited(_save());
    }
  }

  Future<void> _addCondition(int globalIndex) async {
    if (globalIndex < 0 || globalIndex >= _relatives.length) return;
    final rel = _relatives[globalIndex];
    final used = rel.conditions
        .map((c) => c.conditionId)
        .where((id) => id > 0)
        .toSet();
    final available = widget.medicalConditions
        .where((e) => e.id > 0 && !used.contains(e.id))
        .toList(growable: false);

    if (widget.medicalConditions.isEmpty) {
      AppLogger.instance.w(
        '[FamilyHistory] _addCondition blocked — medicalConditions empty',
      );
      _toast('Medical condition list is still loading or empty.');
      return;
    }

    final useOtherFirst = available.isEmpty;
    int conditionId =
        useOtherFirst ? _kOtherChoiceId : available.first.id;
    String conditionName = useOtherFirst ? '' : available.first.name;

    final condition = await showDialog<PatientFamilyConditionRow>(
      context: context,
      builder: (dialogCtx) {
        return DialogControllerScope(
          controllerCount: 1,
          builder: (context, ctrls) {
            final customNameCtl = ctrls[0];
            return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(
                'Add condition — ${rel.displayTitle}',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: conditionId == _kOtherChoiceId
                          ? _kOtherChoiceId
                          : (conditionId > 0 ? conditionId : null),
                      isExpanded: true,
                      decoration: _fieldDecoration(hint: 'Condition'),
                      items: [
                        ...available.map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.name),
                          ),
                        ),
                        const DropdownMenuItem(
                          value: _kOtherChoiceId,
                          child: Text(_kOtherChoiceLabel),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setLocal(() {
                          if (v == _kOtherChoiceId) {
                            conditionId = _kOtherChoiceId;
                            conditionName = '';
                          } else {
                            conditionId = v;
                            conditionName = _labelForId(available, v);
                            customNameCtl.clear();
                          }
                        });
                      },
                    ),
                    if (conditionId == _kOtherChoiceId) ...[
                      SizedBox(height: 12.h),
                      TextField(
                        controller: customNameCtl,
                        decoration: _fieldDecoration(
                          hint: 'Custom condition name',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final isOther = conditionId == _kOtherChoiceId;
                    final custom = customNameCtl.text.trim();
                    if (isOther && custom.isEmpty) {
                      _toast('Enter a custom condition name.');
                      return;
                    }
                    if (!isOther && conditionId <= 0) {
                      _toast('Select a condition.');
                      return;
                    }
                    Navigator.pop(
                      dialogCtx,
                      PatientFamilyConditionRow(
                        relativeConditionId: '',
                        conditionId:
                            isOther ? _kOtherChoiceId : conditionId,
                        conditionName: isOther ? '' : conditionName,
                        customConditionName: isOther ? custom : '',
                      ),
                    );
                  },
                  child: const Text('Add condition'),
                ),
              ],
            );
          },
            );
          },
        );
      },
    );

    if (condition == null || !mounted) return;

    setState(() {
      final current = _relatives[globalIndex];
      final updated = [..._relatives];
      updated[globalIndex] = current.copyWith(
        conditions: [...current.conditions, condition],
      );
      _relatives = updated;
    });
    if (widget.readOnly && widget.allowAdd) {
      unawaited(_save());
    }
  }

  Future<void> _deleteRelative(int globalIndex) async {
    if (globalIndex < 0 || globalIndex >= _relatives.length) return;
    final row = _relatives[globalIndex];
    final ok = await _confirmDelete(
      title: row.isDraft ? 'Discard relative?' : 'Delete relative?',
      message: row.isDraft
          ? '“${row.displayTitle}” will be removed from this draft.'
          : '“${row.displayTitle}” will be deleted from the server.',
    );
    if (!ok || !mounted) return;

    if (row.isDraft) {
      setState(() => _relatives = [..._relatives]..removeAt(globalIndex));
      widget.onRelativesChanged?.call(_relatives);
      return;
    }

    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) return;

    try {
      await widget.patientApi.deleteFamilyRelative(
        patientId: widget.patientId,
        relativeId: row.relativeId,
        bearerToken: token,
      );
      if (!mounted) return;
      setState(() {
        _relatives = [..._relatives]
          ..removeWhere((r) => r.relativeId == row.relativeId);
      });
      widget.onRelativesChanged?.call(_relatives);
      _toast('Relative deleted.');
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    }
  }

  Future<void> _deleteCondition(int globalIndex, int condIndex) async {
    if (globalIndex < 0 || globalIndex >= _relatives.length) return;
    final rel = _relatives[globalIndex];
    if (condIndex < 0 || condIndex >= rel.conditions.length) return;
    final cond = rel.conditions[condIndex];

    final ok = await _confirmDelete(
      title: cond.isDraft ? 'Remove condition?' : 'Delete condition?',
      message: cond.displayConditionName.isNotEmpty
          ? '“${cond.displayConditionName}” will be removed.'
          : 'This condition will be removed.',
    );
    if (!ok || !mounted) return;

    if (cond.isDraft) {
      setState(() {
        final updated = [...rel.conditions]..removeAt(condIndex);
        final list = [..._relatives];
        list[globalIndex] = rel.copyWith(conditions: updated);
        _relatives = list;
      });
      widget.onRelativesChanged?.call(_relatives);
      return;
    }

    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) return;

    try {
      await widget.patientApi.deleteFamilyCondition(
        patientId: widget.patientId,
        relativeConditionId: cond.relativeConditionId,
        bearerToken: token,
      );
      if (!mounted) return;
      setState(() {
        final updated = [...rel.conditions]
          ..removeWhere(
            (c) => c.relativeConditionId == cond.relativeConditionId,
          );
        final list = [..._relatives];
        list[globalIndex] = rel.copyWith(conditions: updated);
        _relatives = list;
      });
      widget.onRelativesChanged?.call(_relatives);
      _toast('Condition deleted.');
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    }
  }

  Color _degreeAccent(int? degreeId) {
    if (degreeId == null || degreeId <= 0) {
      return AppColors.dashboardWarning;
    }
    final name = _labelForId(widget.relationDegrees, degreeId).toLowerCase();
    if (name.contains('1')) return AppColors.dashboardPrimary;
    if (name.contains('2')) return AppColors.followAccentPurple;
    if (name.contains('3')) return AppColors.followAccentGreen;
    return AppColors.dashboardWarning;
  }

  Widget _relativeAvatarChip(String title, Color accent) {
    final initials = NameInitials.fromFullName(title);
    return Container(
      padding: EdgeInsets.all(2.5.r),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 24.r,
        backgroundColor: accent.withValues(alpha: 0.12),
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w900,
            color: accent,
          ),
        ),
      ),
    );
  }

  Widget _conditionPill(
    String label, {
    required Color accent,
    VoidCallback? onDelete,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(10.w, 6.h, onDelete == null ? 10.w : 4.w, 6.h),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monitor_heart_outlined,
            size: 12.sp,
            color: accent,
          ),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          if (onDelete != null) ...[
            SizedBox(width: 2.w),
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: EdgeInsets.all(3.r),
                child: Icon(
                  Icons.close_rounded,
                  size: 14.sp,
                  color: accent.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _familyPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool filled = true,
  }) {
    return Material(
      color: filled ? AppColors.dashboardPrimary : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: filled
                ? null
                : Border.all(
                    color: AppColors.dashboardPrimary.withValues(alpha: 0.35),
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16.sp,
                color: filled ? AppColors.surface : AppColors.dashboardPrimary,
              ),
              SizedBox(width: 5.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: filled ? AppColors.surface : AppColors.dashboardPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _familyAddConditionButton({required VoidCallback onPressed}) {
    return _familyPrimaryButton(
      label: 'Add condition',
      icon: Icons.add_rounded,
      onPressed: onPressed,
      filled: false,
    );
  }

  Widget _entryMoreMenu({
    required VoidCallback onDelete,
    double iconSize = 22,
  }) {
    return PopupMenuButton<String>(
      tooltip: 'More options',
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: 140.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      color: AppColors.surface,
      elevation: 4,
      icon: Icon(
        Icons.more_vert_rounded,
        size: iconSize.sp,
        color: AppColors.dashboardPrimaryDark,
      ),
      onSelected: (value) {
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'delete',
          height: 44.h,
          child: Text(
            'Delete',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.danger,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration({String? hint}) {
    final radius = BorderRadius.circular(12.r);
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.registrationFieldFill,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      border: OutlineInputBorder(borderRadius: radius),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.registrationFieldBorder),
      ),
    );
  }

  Widget _familyHistoryHeader({
    required int visibleCount,
    required int totalCount,
    required Color accent,
  }) {
    final degreeLabel = _degreeId == null
        ? 'All degrees'
        : _labelForId(widget.relationDegrees, _degreeId!);
    final subtitle = widget.readOnly
        ? 'Recorded relatives and their medical conditions'
        : 'Add relatives by degree and note their conditions';

    return Material(
      elevation: 3,
      shadowColor: accent.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(22.r),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.14),
              AppColors.surface,
            ],
            stops: const [0.0, 0.92],
          ),
          border: Border.all(color: AppColors.registrationFieldBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 24.r,
                backgroundColor: accent.withValues(alpha: 0.14),
                child: Icon(
                  Icons.family_restroom_rounded,
                  size: 24.sp,
                  color: accent,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Family history',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.dashboardPrimaryDark,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: accent.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '$visibleCount in $degreeLabel · $totalCount total',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _degreeTabBar() {
    final degrees = widget.relationDegrees.where((e) => e.id > 0).toList();
    if (degrees.isEmpty) {
      AppLogger.instance.w(
        '[FamilyHistory] _degreeTabBar hidden — no relationDegrees with id > 0',
      );
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.registrationFieldBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.dashboardPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: degrees.map((d) {
            final selected = _degreeId == d.id;
            final accent = _degreeAccent(d.id);
            final count =
                _relatives.where((r) => r.relationDegreeId == d.id).length;
            return Padding(
              padding: EdgeInsets.only(right: 6.w),
              child: Material(
                color: selected ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(12.r),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => setState(() => _degreeId = d.id),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_tree_outlined,
                          size: 15.sp,
                          color: selected
                              ? AppColors.surface
                              : AppColors.textSecondary,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          d.name,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? AppColors.surface
                                : AppColors.dashboardPrimaryDark,
                          ),
                        ),
                        if (count > 0) ...[
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.surface.withValues(alpha: 0.22)
                                  : accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                                color: selected ? AppColors.surface : accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _relativeCard({
    required PatientFamilyRelativeRow rel,
    required int globalIndex,
    required Color accent,
  }) {
    return Material(
      color: AppColors.surface,
      elevation: 3,
      shadowColor: accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20.r),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4.w, color: accent),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 14.h, 12.w, 14.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _relativeAvatarChip(rel.displayTitle, accent),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rel.displayTitle,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.dashboardPrimaryDark,
                                  ),
                                ),
                                if (rel.relationDegreeName.trim().isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(top: 4.h),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 3.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        rel.relationDegreeName,
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w800,
                                          color: accent,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (rel.isDraft)
                            Container(
                              margin: EdgeInsets.only(right: 4.w),
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.dashboardPeach
                                    .withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.dashboardPeachBorder,
                                ),
                              ),
                              child: Text(
                                'Draft',
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.dashboardWarning,
                                ),
                              ),
                            ),
                          if (!widget.readOnly)
                            _entryMoreMenu(
                              onDelete: () =>
                                  unawaited(_deleteRelative(globalIndex)),
                            ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: AppColors.registrationFieldFill
                              .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: AppColors.registrationFieldBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.medical_information_outlined,
                                  size: 15.sp,
                                  color: accent,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'Medical conditions',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.registrationSectionLabel,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            if (rel.conditions.isEmpty)
                              Column(
                                children: [
                                  Text(
                                    'No conditions recorded yet.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (widget.allowAdd) ...[
                                    SizedBox(height: 10.h),
                                    Align(
                                      alignment: Alignment.center,
                                      child: _familyAddConditionButton(
                                        onPressed: () => unawaited(
                                          _addCondition(globalIndex),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            else
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 8.h,
                                children: [
                                  for (int ci = 0;
                                      ci < rel.conditions.length;
                                      ci++)
                                    _conditionPill(
                                      rel.conditions[ci].displayConditionName,
                                      accent: accent,
                                      onDelete: widget.readOnly
                                          ? null
                                          : () => unawaited(
                                                _deleteCondition(
                                                  globalIndex,
                                                  ci,
                                                ),
                                              ),
                                    ),
                                ],
                              ),
                            if (widget.allowAdd && rel.conditions.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 10.h),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _familyAddConditionButton(
                                    onPressed: () =>
                                        unawaited(_addCondition(globalIndex)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyDegreeState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.registrationFieldBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.dashboardPrimary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.dashboardPeach.withValues(alpha: 0.35),
              border: Border.all(
                color: AppColors.dashboardWarning.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              Icons.family_restroom_outlined,
              size: 34.sp,
              color: AppColors.dashboardWarning.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            widget.readOnly
                ? 'No relatives in this degree'
                : 'Start building family history',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.dashboardPrimaryDark,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            widget.readOnly
                ? 'Nothing has been recorded for this relation degree yet.'
                : 'Add a parent, sibling, or other relative and list any illnesses they have had.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (widget.allowAdd) ...[
            SizedBox(height: 16.h),
            _familyPrimaryButton(
              label: 'Add relative',
              icon: Icons.person_add_alt_1_rounded,
              onPressed: _addRelative,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = SizedBox(
      height: MediaQuery.paddingOf(context).bottom + 12.h,
    );

    if (_loading && !_loaded) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.all(32.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 34.r,
                  height: 34.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.dashboardWarning,
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  'Loading family history…',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          bottomInset,
        ],
      );
    }

    final visible = _relativesForDegree();
    final accent = _degreeAccent(_degreeId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _familyHistoryHeader(
          visibleCount: visible.length,
          totalCount: _relatives.length,
          accent: accent,
        ),
        SizedBox(height: 14.h),
        _degreeTabBar(),
        SizedBox(height: 14.h),
        if (widget.allowAdd)
          Align(
            alignment: Alignment.centerRight,
            child: _familyPrimaryButton(
              label: 'Add relative',
              icon: Icons.person_add_alt_1_rounded,
              onPressed: _addRelative,
            ),
          ),
        SizedBox(height: 14.h),
        if (visible.isEmpty)
          _emptyDegreeState()
        else
          ...visible.map((rel) {
            final globalIndex = _globalIndexFor(rel);
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _relativeCard(
                rel: rel,
                globalIndex: globalIndex,
                accent: accent,
              ),
            );
          }),
        if (!widget.readOnly)
          Padding(
            padding: EdgeInsets.only(top: 20.h),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.registrationSaveBlue,
                foregroundColor: AppColors.surface,
                minimumSize: Size(double.infinity, 52.h),
                elevation: 2,
                shadowColor:
                    AppColors.registrationSaveBlue.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: _saving
                  ? SizedBox(
                      width: 22.r,
                      height: 22.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.surface,
                      ),
                    )
                  : Text(
                      'Save family history',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        bottomInset,
      ],
    );
  }
}
