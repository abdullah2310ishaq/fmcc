import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

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
  });

  final String patientId;
  final PatientApi patientApi;
  final List<NamedReferenceItem> medicalConditions;
  final List<NamedReferenceItem> relationDegrees;

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
    _logFamilyState('initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadWhenReady());
    });
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
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(fontSize: 16.sp)),
        content: Text(message, style: TextStyle(fontSize: 13.sp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
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
      _toast('Condition deleted.');
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    }
  }

  Widget _entryDeleteButton({
    required VoidCallback onPressed,
    double size = 24,
  }) {
    return Tooltip(
      message: 'Delete',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10.r),
          child: Padding(
            padding: EdgeInsets.all(6.r),
            child: Image.asset(
              'assets/delete.png',
              width: size.r,
              height: size.r,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.delete_outline_rounded,
                  size: size.sp,
                  color: AppColors.dashboardPrimaryDark,
                );
              },
            ),
          ),
        ),
      ),
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

  Widget _degreeTabBar() {
    final degrees = widget.relationDegrees.where((e) => e.id > 0).toList();
    if (degrees.isEmpty) {
      AppLogger.instance.w(
        '[FamilyHistory] _degreeTabBar hidden — no relationDegrees with id > 0',
      );
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: degrees.map((d) {
          final selected = _degreeId == d.id;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Material(
              color: selected
                  ? AppColors.dashboardPrimary
                  : AppColors.dashboardChipBlueBg,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => setState(() => _degreeId = d.id),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  child: Text(
                    d.name,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? AppColors.surface
                          : AppColors.dashboardPrimaryDark,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
            padding: EdgeInsets.all(24.r),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.dashboardPrimary,
              ),
            ),
          ),
          bottomInset,
        ],
      );
    }

    final visible = _relativesForDegree();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _degreeTabBar(),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: Text(
                'Add relatives and their illnesses by degree (1st / 2nd / 3rd).',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
            Material(
              color: AppColors.dashboardPrimary,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _addRelative,
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 16.sp, color: AppColors.surface),
                      SizedBox(width: 4.w),
                      Text(
                        'Add relative',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.surface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        if (visible.isEmpty)
          Text(
            'No relatives in this degree yet. Tap “Add relative”.',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          )
        else
          ...visible.map((rel) {
            final globalIndex = _globalIndexFor(rel);
            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.registrationFieldFill.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(13.r),
                border: Border.all(color: AppColors.registrationFieldBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rel.displayTitle,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (rel.relationDegreeName.trim().isNotEmpty &&
                                rel.specificRelation.trim().isNotEmpty)
                              Text(
                                rel.relationDegreeName,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (rel.isDraft)
                        Container(
                          margin: EdgeInsets.only(right: 6.w),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.dashboardPeach
                                .withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'New',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.dashboardWarning,
                            ),
                          ),
                        ),
                      _entryDeleteButton(
                        onPressed: () =>
                            unawaited(_deleteRelative(globalIndex)),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Conditions',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.registrationSectionLabel,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  if (rel.conditions.isEmpty)
                    Text(
                      'No conditions added yet.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    ...List.generate(rel.conditions.length, (ci) {
                      final c = rel.conditions[ci];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.displayConditionName,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _entryDeleteButton(
                              size: 20,
                              onPressed: () => unawaited(
                                _deleteCondition(globalIndex, ci),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => unawaited(_addCondition(globalIndex)),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add condition'),
                    ),
                  ),
                ],
              ),
            );
          }),
        Padding(
          padding: EdgeInsets.only(top: 20.h),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.registrationSaveBlue,
              foregroundColor: AppColors.surface,
              minimumSize: Size(double.infinity, 52.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: Text(
              _saving ? 'Saving…' : 'Save Family History',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        bottomInset,
      ],
    );
  }
}
