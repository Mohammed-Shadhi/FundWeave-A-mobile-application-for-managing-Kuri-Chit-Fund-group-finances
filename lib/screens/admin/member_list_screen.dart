import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';
import 'member_detail_admin_screen.dart';

// ── Country Code Data ──
class _Country {
  final String name;
  final String flag;
  final String dialCode;
  const _Country(this.name, this.flag, this.dialCode);
}

const List<_Country> _kCountries = [
  _Country('India',                '🇮🇳', '+91'),
  _Country('United States',        '🇺🇸', '+1'),
  _Country('United Kingdom',       '🇬🇧', '+44'),
  _Country('United Arab Emirates', '🇦🇪', '+971'),
  _Country('Saudi Arabia',         '🇸🇦', '+966'),
  _Country('Canada',               '🇨🇦', '+1'),
  _Country('Australia',            '🇦🇺', '+61'),
  _Country('Germany',              '🇩🇪', '+49'),
  _Country('France',               '🇫🇷', '+33'),
  _Country('Singapore',            '🇸🇬', '+65'),
  _Country('Malaysia',             '🇲🇾', '+60'),
  _Country('Bangladesh',           '🇧🇩', '+880'),
  _Country('Pakistan',             '🇵🇰', '+92'),
  _Country('Sri Lanka',            '🇱🇰', '+94'),
  _Country('Nepal',                '🇳🇵', '+977'),
  _Country('Qatar',                '🇶🇦', '+974'),
  _Country('Kuwait',               '🇰🇼', '+965'),
  _Country('Bahrain',              '🇧🇭', '+973'),
  _Country('Oman',                 '🇴🇲', '+968'),
  _Country('South Africa',         '🇿🇦', '+27'),
];

class MemberListScreen extends ConsumerStatefulWidget {
  final String shopId;
  final String shopName;
  final String uid;
  const MemberListScreen({
    super.key,
    required this.shopId,
    required this.shopName,
    required this.uid,
  });

  @override
  ConsumerState<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends ConsumerState<MemberListScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  String searchQuery = '';
  bool isSearching = false;

  static const Color _primaryBlue = Color(0xFF0F4CFF);
  static const Color _primaryTeal = Color(0xFF14D8C4);
  static const Color _darkNavy    = Color(0xFF0A1F44);

  @override
  void initState() {
    super.initState();
    searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchCtrl.removeListener(_onSearchChanged);
    searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = searchCtrl.text.trim().toLowerCase();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && q != searchQuery) {
        setState(() => searchQuery = q);
      }
    });
  }

  // ── Country picker bottom sheet ──
  Future<_Country> _pickCountry(BuildContext ctx, _Country current) async {
    final filterCtrl = TextEditingController();
    List<_Country> filtered = List.from(_kCountries);
    _Country selected = current;

    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          builder: (_, scrollCtrl) => Column(children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            const Text('Select Country Code',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _darkNavy)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: filterCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 0, horizontal: 16),
                ),
                onChanged: (val) => setSheet(() {
                  filtered = _kCountries
                      .where((c) =>
                          c.name.toLowerCase().contains(val.toLowerCase()) ||
                          c.dialCode.contains(val))
                      .toList();
                }),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final c = filtered[i];
                  final isSel = c.name == selected.name;
                  return ListTile(
                    leading: Text(c.flag,
                        style: const TextStyle(fontSize: 24)),
                    title: Text(c.name,
                        style: TextStyle(
                            fontWeight: isSel
                                ? FontWeight.bold
                                : FontWeight.normal)),
                    trailing: Text(c.dialCode,
                        style: TextStyle(
                            color: isSel
                                ? _primaryBlue
                                : Colors.grey.shade600,
                            fontWeight: isSel
                                ? FontWeight.bold
                                : FontWeight.normal)),
                    selected: isSel,
                    selectedTileColor: _primaryBlue.withOpacity(0.05),
                    onTap: () {
                      selected = c;
                      Navigator.pop(sheetCtx);
                    },
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
    return selected;
  }

  // ── Show Add Member Dialog ──
  Future<void> _showAddMemberDialog() async {
    await showDialog(
      context: context,
      // Let Flutter resize the dialog when keyboard appears
      barrierDismissible: true,
      builder: (ctx) => _AddMemberDialog(
        shopId:        widget.shopId,
        shopName:      widget.shopName,
        onPickCountry: (current) => _pickCountry(ctx, current),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(shopMembersProvider(widget.shopId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: isSearching
            ? const SizedBox.shrink()
            : const Text('Directory',
                style: TextStyle(
                    fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: _darkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search, size: 24),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  searchCtrl.clear();
                  searchQuery = '';
                }
              });
            },
          ),
        ],
        bottom: isSearching
            ? PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Search by name, member ID...',
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.search,
                          color: Colors.white.withOpacity(0.7)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: Column(children: [
        if (!isSearching)
          membersAsync.when(
            data: (members) => Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(children: [
                const Icon(Icons.people_alt,
                    color: _primaryBlue, size: 20),
                const SizedBox(width: 10),
                Text(
                  '${members.length} Total Member${members.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _darkNavy,
                      fontSize: 15),
                ),
              ]),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        Expanded(
          child: searchQuery.isNotEmpty
              ? _buildSearchResults()
              : _buildAllMembers(membersAsync),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMemberDialog,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Member',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  Widget _buildAllMembers(AsyncValue<List<MemberModel>> membersAsync) {
    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 80, color: _primaryBlue.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text('No members yet.',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Tap + to build your community',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: members.length,
          itemBuilder: (context, i) => _memberCard(members[i]),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: _primaryBlue)),
      error: (e, _) =>
          Center(child: ErrorMessage(message: e.toString())),
    );
  }

  Widget _buildSearchResults() {
    final resultsAsync = ref.watch(searchResultsProvider(
        (shopId: widget.shopId, query: searchQuery)));
    return resultsAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off,
                      size: 70, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No results found.',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: members.length,
          itemBuilder: (context, i) => _memberCard(members[i]),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: _primaryBlue)),
      error: (e, _) =>
          Center(child: ErrorMessage(message: e.toString())),
    );
  }

  Widget _memberCard(MemberModel member) {
    final initial =
        member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : 'M';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => MemberDetailAdminScreen(
                      member: member,
                      shopId: widget.shopId,
                      shopName: widget.shopName,
                    ))),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _primaryTeal, width: 1.5),
          ),
          child: CircleAvatar(
            backgroundColor: _primaryBlue.withOpacity(0.1),
            radius: 24,
            child: Text(initial,
                style: const TextStyle(
                    color: _primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
          ),
        ),
        title: Text(member.fullName,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _darkNavy)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.phone, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(member.phone,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black87)),
                ]),
                const SizedBox(height: 2),
                Text(member.displayId,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500)),
              ]),
        ),
        isThreeLine: true,
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _primaryTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _primaryTeal.withOpacity(0.3)),
          ),
          child: Text(member.memberNumber,
              style: const TextStyle(
                  color: _primaryTeal,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
// ADD MEMBER DIALOG
// ══════════════════════════════════════════
// FIX — keyboard overflow: uses AlertDialog (not Dialog) with
// SingleChildScrollView so Flutter's default keyboard-avoidance
// handles the resize without any manual viewInsets math.
//
// FIX — invite flow: writes to 'invitations/{phone}' which is
// exactly what _InviteButton in member_dashboard.dart listens to.
// The member sees a banner, taps it, and accepts via InvitationScreen.
// ══════════════════════════════════════════
class _AddMemberDialog extends StatefulWidget {
  final String shopId;
  final String shopName;
  final Future<_Country> Function(_Country current) onPickCountry;

  const _AddMemberDialog({
    required this.shopId,
    required this.shopName,
    required this.onPickCountry,
  });

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  static const Color _primaryBlue = Color(0xFF0F4CFF);
  static const Color _darkNavy    = Color(0xFF0A1F44);

  final _searchCtrl    = TextEditingController();
  _Country _country    = _kCountries.first;

  List<Map<String, dynamic>> _results = [];
  bool    _loading     = false;
  bool    _success     = false;
  String? _successName;
  String? _errorMsg;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSearch(String raw) async {
    if (raw.trim().isEmpty) {
      setState(() { _results = []; _errorMsg = null; });
      return;
    }
    setState(() { _loading = true; _errorMsg = null; });

    try {
      final isDigits = RegExp(r'^\d+$').hasMatch(raw.trim());
      final Map<String, Map<String, dynamic>> merged = {};

      if (isDigits) {
        final phone = '${_country.dialCode}${raw.trim()}';
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isGreaterThanOrEqualTo: phone)
            .where('phone', isLessThanOrEqualTo: '$phone\uf8ff')
            .limit(10)
            .get();
        for (final d in snap.docs) {
          merged[d.id] = {...d.data(), 'uid': d.id};
        }
      } else {
        for (final q in [raw.trim(), raw.trim().toLowerCase()]) {
          final snap = await FirebaseFirestore.instance
              .collection('users')
              .orderBy('fullName')
              .startAt([q])
              .endAt(['$q\uf8ff'])
              .limit(10)
              .get();
          for (final d in snap.docs) {
            merged[d.id] = {...d.data(), 'uid': d.id};
          }
        }
      }

      setState(() { _results = merged.values.toList(); _loading = false; });
    } catch (e) {
      setState(() { _errorMsg = 'Search failed: $e'; _loading = false; });
    }
  }

  // ── Send invitation — writes to invitations/{phone} ──
  // member_dashboard.dart's _InviteButton listens to this exact doc.
  // The member sees a pending banner and accepts via InvitationScreen.
  Future<void> _sendInvite(Map<String, dynamic> user) async {
    setState(() { _loading = true; _errorMsg = null; });

    final phone    = user['phone']    as String? ?? '';
    final fullName = user['fullName'] as String? ?? 'Unknown';
    final userId   = user['uid']      as String;

    if (phone.isEmpty) {
      setState(() {
        _errorMsg = 'This user has no phone number on record.';
        _loading  = false;
      });
      return;
    }

    try {
      // ── Guard: already a member of this shop ──
      final existingSnap = await FirebaseFirestore.instance
          .collection('members')
          .where('uid',    isEqualTo: userId)
          .where('shopId', isEqualTo: widget.shopId)
          .limit(1)
          .get();

      if (existingSnap.docs.isNotEmpty) {
        setState(() {
          _errorMsg = '$fullName is already a member of this shop.';
          _loading  = false;
        });
        return;
      }

      // ── Guard: invitation already pending ──
      final existingInvite = await FirebaseFirestore.instance
          .collection('invitations')
          .doc(phone)
          .get();

      if (existingInvite.exists) {
        final existingShopId =
            existingInvite.data()?['shopId'] as String? ?? '';
        if (existingShopId == widget.shopId) {
          setState(() {
            _errorMsg =
                'An invitation has already been sent to $fullName.';
            _loading = false;
          });
          return;
        }
      }

      // ── Write invitation doc keyed by phone ──
      // This is the doc that _InviteButton in member_dashboard streams.
      await FirebaseFirestore.instance
          .collection('invitations')
          .doc(phone)
          .set({
        'phone':     phone,
        'fullName':  fullName,
        'userId':    userId,
        'shopId':    widget.shopId,
        'shopName':  widget.shopName,
        'status':    'pending',
        'invitedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _success     = true;
        _successName = fullName;
        _loading     = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Error sending invitation: $e';
        _loading  = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding:   const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.person_search,
              color: _primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        const Text('Add Member',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
      // SingleChildScrollView prevents overflow when keyboard appears
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: _success ? _buildSuccess() : _buildSearch(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            _success ? 'Done' : 'Cancel',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_rounded,
              color: Colors.green, size: 48),
        ),
        const SizedBox(height: 16),
        Text('Invitation sent to $_successName!',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          '$_successName will see a notification to join ${widget.shopName}.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSearch() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search row
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(children: [
            GestureDetector(
              onTap: () async {
                final picked = await widget.onPickCountry(_country);
                setState(() {
                  _country = picked;
                  if (_searchCtrl.text.isNotEmpty) _doSearch(_searchCtrl.text);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                      right: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_country.flag,
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 4),
                  Text(_country.dialCode,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _darkNavy)),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down,
                      size: 16, color: Colors.grey.shade500),
                ]),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Name or phone digits...',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400, fontSize: 13),
                  suffixIcon: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.search,
                          size: 18, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                ),
                onChanged: (val) {
                  Future.delayed(const Duration(milliseconds: 400), () {
                    if (mounted && _searchCtrl.text == val) {
                      _doSearch(val);
                    }
                  });
                },
              ),
            ),
          ]),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Enter digits only to search by phone, or type a name.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ),

        // Error
        if (_errorMsg != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_errorMsg!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 12)),
              ),
            ]),
          ),

        // Results
        if (_results.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (_, i) {
                final user     = _results[i];
                final name     = user['fullName'] as String? ?? 'Unknown';
                final phone    = user['phone']    as String? ?? '';
                final username = user['username'] as String? ?? '';
                final initial  = name.isNotEmpty
                    ? name[0].toUpperCase()
                    : 'U';

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: _primaryBlue.withOpacity(0.1),
                        child: Text(initial,
                            style: const TextStyle(
                                color: _primaryBlue,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                                overflow: TextOverflow.ellipsis),
                            if (phone.isNotEmpty)
                              Row(children: [
                                const Icon(Icons.phone,
                                    size: 11, color: Colors.grey),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(phone,
                                      style:
                                          const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ]),
                            if (username.isNotEmpty)
                              Row(children: [
                                const Icon(Icons.alternate_email,
                                    size: 11, color: Colors.grey),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text('@$username',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ]),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: _loading
                              ? null
                              : () => _sendInvite(user),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 13),
                              SizedBox(width: 4),
                              Text('Invite',
                                  style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        else if (!_loading && _searchCtrl.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(children: [
              Icon(Icons.person_search,
                  size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text('No users found.',
                  style: TextStyle(color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Text(
                'Make sure they have registered in the app first.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ]),
          )
        else if (_searchCtrl.text.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'Search by name or phone number\nto find registered users.',
              style:
                  TextStyle(color: Colors.grey.shade400, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}