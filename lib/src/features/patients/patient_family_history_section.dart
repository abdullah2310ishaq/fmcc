import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:doctor_app/src/core/network/api_failure.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_load());
    });
  }

  @override
  void didUpdateWidget(covariant PatientFamilyHistorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_degreeId == null && widget.relationDegrees.isNotEmpty) {
      _degreeId = _firstPositiveId(widget.relationDegrees);
    }
  }

  int? _firstPositiveId(List<NamedReferenceItem> items) {
    for (final e in items) {
      if (e.id > 0) return e.id;
    }
    return null;
  }

  int _allocTempRelativeId() => --_tempRelativeIdSeq;

  String _labelForId(List<NamedReferenceItem> items, int id) {
    for (final e in items) {
      if (e.id == id) return e.name;
    }
    return '';
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: TextStyle(fontSize: 14.sp))),
    );
  }

  Future<void> _load() async {
    final session = context.read<SessionController>();
    final token = session.state.accessToken?.trim();
    if (token == null || token.isEmpty) return;

    setState(() => _loading = true);
    try {
      final data = await widget.patientApi.getFamilyHistory(
        patientId: widget.patientId,
        bearerToken: token,
      );
      if (!mounted) return;
      setState(() {
        _relatives = data?.relatives ?? const [];
        _loaded = true;
      });
    } on Object catch (e) {
      if (!mounted || e is SessionEndedFailure) return;
      _toast(session.apiClient.mapError(e).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<PatientFamilyRelativeRow> _relativesForDegree() {
    final d = _degreeId;
    if (d == null || d <= 0) return _relatives;
    return _relatives.where((r) => r.relationDegreeId == d).toList();
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
      _toast('Family history saved.');
      await _load();
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
    final defaultDegree = _degreeId ?? _firstPositiveId(widget.relationDegrees);
    if (defaultDegree == null || widget.relationDegrees.isEmpty) {
      _toast('Relation degree list is still loading or empty.');
      return;
    }

    int relationDegreeId = defaultDegree;
    String relationDegreeName =
        _labelForId(widget.relationDegrees, defaultDegree);
    final specificCtl = TextEditingController();

    final row = await showDialog<PatientFamilyRelativeRow>(
      context: context,
      builder: (dialogCtx) {
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

    specificCtl.dispose();
    if (row == null || !mounted) return;
    setState(() => _relatives = [..._relatives, row]);
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
      _toast('Medical condition list is still loading or empty.');
      return;
    }

    final useOtherFirst = available.isEmpty;
    int conditionId =
        useOtherFirst ? _kOtherChoiceId : available.first.id;
    String conditionName = useOtherFirst ? '' : available.first.name;
    final customNameCtl = TextEditingController();

    final condition = await showDialog<PatientFamilyConditionRow>(
      context: context,
      builder: (dialogCtx) {
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

    customNameCtl.dispose();
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
      message: '“${cond.displayConditionName}” will be removed.',
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
    if (degrees.isEmpty) return const SizedBox.shrink();

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
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: AppColors.dashboardPrimaryDark,
                        onPressed: () => unawaited(_deleteRelative(globalIndex)),
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
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              color: AppColors.textSecondary,
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
